import Foundation
import ExternalAccessory

/// Bluetooth Classic (MFi アクセサリ) 通信マネージャー
///
/// ExternalAccessory フレームワークを使用して MFi 認定アクセサリと通信します。
/// Info.plist の UISupportedExternalAccessoryProtocols に
/// アクセサリのプロトコル文字列を追加する必要があります。
class BluetoothClassicManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var connectedAccessories: [AccessoryInfo] = []
    @Published var selectedAccessory: AccessoryInfo?
    @Published var isSessionOpen: Bool = false
    @Published var messages: [Message] = []
    @Published var currentProtocol: String = ""
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private var session: EASession?
    private var inputStream: InputStream?
    private var outputStream: OutputStream?
    private var pendingWriteData: Data = Data()
    private let readBufferSize = 4096

    // MARK: - Init

    override init() {
        super.init()
        setupNotifications()
        refreshAccessories()
    }

    deinit {
        EAAccessoryManager.shared().unregisterForLocalNotifications()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Notification Setup

    private func setupNotifications() {
        EAAccessoryManager.shared().registerForLocalNotifications()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessoryDidConnect(_:)),
            name: .EAAccessoryDidConnect,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessoryDidDisconnect(_:)),
            name: .EAAccessoryDidDisconnect,
            object: nil
        )
    }

    // MARK: - Accessory Management

    func refreshAccessories() {
        DispatchQueue.main.async {
            self.connectedAccessories = EAAccessoryManager.shared()
                .connectedAccessories
                .map { AccessoryInfo(accessory: $0) }
        }
    }

    @objc private func accessoryDidConnect(_ notification: Notification) {
        refreshAccessories()
    }

    @objc private func accessoryDidDisconnect(_ notification: Notification) {
        if let accessory = notification.userInfo?[EAAccessoryKey] as? EAAccessory,
           accessory.connectionID == selectedAccessory?.connectionID {
            DispatchQueue.main.async {
                self.closeSession()
            }
        }
        refreshAccessories()
    }

    // MARK: - Session Management

    /// 指定したアクセサリとプロトコルでセッションを開く
    func openSession(for accessoryInfo: AccessoryInfo, protocolString: String) {
        closeSession()

        guard let eaSession = EASession(accessory: accessoryInfo.accessory, forProtocol: protocolString) else {
            DispatchQueue.main.async {
                self.errorMessage = "セッションの作成に失敗しました。\nプロトコル文字列「\(protocolString)」を確認してください。\nInfo.plist の UISupportedExternalAccessoryProtocols にも追加が必要です。"
            }
            return
        }

        session = eaSession
        currentProtocol = protocolString

        if let stream = eaSession.inputStream {
            inputStream = stream
            stream.delegate = self
            stream.schedule(in: .main, forMode: .default)
            stream.open()
        }

        if let stream = eaSession.outputStream {
            outputStream = stream
            stream.delegate = self
            stream.schedule(in: .main, forMode: .default)
            stream.open()
        }

        DispatchQueue.main.async {
            self.selectedAccessory = accessoryInfo
            self.isSessionOpen = true
        }
    }

    /// セッションを閉じる
    func closeSession() {
        inputStream?.close()
        inputStream?.remove(from: .main, forMode: .default)
        inputStream = nil

        outputStream?.close()
        outputStream?.remove(from: .main, forMode: .default)
        outputStream = nil

        session = nil
        pendingWriteData = Data()

        DispatchQueue.main.async {
            self.selectedAccessory = nil
            self.isSessionOpen = false
            self.currentProtocol = ""
        }
    }

    // MARK: - Data Transfer

    /// テキストメッセージを送信する
    func send(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        pendingWriteData.append(data)
        writeAvailableData()

        let message = Message(content: text, timestamp: Date(), isSent: true)
        DispatchQueue.main.async {
            self.messages.append(message)
        }
    }

    /// バイナリデータを送信する
    func sendData(_ data: Data) {
        pendingWriteData.append(data)
        writeAvailableData()
    }

    private func writeAvailableData() {
        guard let stream = outputStream,
              stream.hasSpaceAvailable,
              !pendingWriteData.isEmpty else { return }

        let bytesWritten = pendingWriteData.withUnsafeBytes { ptr -> Int in
            guard let baseAddress = ptr.baseAddress else { return 0 }
            return stream.write(
                baseAddress.assumingMemoryBound(to: UInt8.self),
                maxLength: pendingWriteData.count
            )
        }

        if bytesWritten > 0 {
            pendingWriteData.removeFirst(bytesWritten)
        }
    }

    private func readAvailableData() {
        guard let stream = inputStream else { return }
        var buffer = [UInt8](repeating: 0, count: readBufferSize)

        while stream.hasBytesAvailable {
            let bytesRead = stream.read(&buffer, maxLength: readBufferSize)
            guard bytesRead > 0 else { break }

            let text = String(bytes: buffer[0..<bytesRead], encoding: .utf8)
                ?? buffer[0..<bytesRead].map { String(format: "%02X", $0) }.joined(separator: " ")

            let message = Message(content: text, timestamp: Date(), isSent: false)
            DispatchQueue.main.async {
                self.messages.append(message)
            }
        }
    }
}

// MARK: - StreamDelegate

extension BluetoothClassicManager: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .hasBytesAvailable:
            readAvailableData()
        case .hasSpaceAvailable:
            writeAvailableData()
        case .errorOccurred:
            let errDesc = aStream.streamError?.localizedDescription ?? "不明なエラー"
            DispatchQueue.main.async {
                self.errorMessage = "ストリームエラー: \(errDesc)"
            }
        case .endEncountered:
            DispatchQueue.main.async {
                self.closeSession()
            }
        default:
            break
        }
    }
}
