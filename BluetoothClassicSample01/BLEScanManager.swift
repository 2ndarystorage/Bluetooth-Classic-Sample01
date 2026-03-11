import Foundation
import CoreBluetooth

/// CoreBluetooth を使った BLE デバイススキャン・接続マネージャー
class BLEScanManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var discoveredDevices: [BLEDeviceInfo] = []
    @Published var isScanning: Bool = false
    @Published var state: CBManagerState = .unknown
    @Published var connectionStates: [UUID: BLEConnectionState] = [:]
    @Published var discoveredServices: [UUID: [CBService]] = [:]
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private var centralManager: CBCentralManager!
    private var scanTimer: Timer?
    private var connectedPeripherals: [UUID: CBPeripheral] = [:]

    // MARK: - Init

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: - Scan Control

    func startScan(duration: TimeInterval = 15.0) {
        guard centralManager.state == .poweredOn else {
            errorMessage = stateDescription(centralManager.state)
            return
        }
        discoveredDevices.removeAll()
        isScanning = true
        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
        if duration > 0 {
            scanTimer?.invalidate()
            scanTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                self?.stopScan()
            }
        }
    }

    func stopScan() {
        centralManager.stopScan()
        scanTimer?.invalidate()
        scanTimer = nil
        isScanning = false
    }

    // MARK: - Connection Control

    /// デバイスに接続する
    func connect(_ device: BLEDeviceInfo) {
        guard centralManager.state == .poweredOn else {
            errorMessage = stateDescription(centralManager.state)
            return
        }
        guard device.isConnectable else {
            errorMessage = "このデバイスは接続をサポートしていません"
            return
        }
        connectionStates[device.uuid] = .connecting
        centralManager.connect(device.peripheral, options: nil)
    }

    /// デバイスを切断する
    func disconnect(_ device: BLEDeviceInfo) {
        guard let peripheral = connectedPeripherals[device.uuid] else { return }
        connectionStates[device.uuid] = .disconnecting
        centralManager.cancelPeripheralConnection(peripheral)
    }

    /// UUID でデバイスを切断する（BLEConnectionView から使用）
    func disconnectByUUID(_ uuid: UUID) {
        guard let peripheral = connectedPeripherals[uuid] else { return }
        connectionStates[uuid] = .disconnecting
        centralManager.cancelPeripheralConnection(peripheral)
    }

    // MARK: - Helpers

    private func stateDescription(_ state: CBManagerState) -> String {
        switch state {
        case .poweredOff:   return "Bluetooth がオフです。設定からオンにしてください。"
        case .unauthorized: return "Bluetooth の使用が許可されていません。設定 > プライバシーから許可してください。"
        case .unsupported:  return "この端末は Bluetooth LE をサポートしていません。"
        case .resetting:    return "Bluetooth をリセット中です。しばらくお待ちください。"
        default:            return "Bluetooth の状態を確認できません。"
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEScanManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        state = central.state
        if central.state != .poweredOn, isScanning {
            stopScan()
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let rssiValue = RSSI.intValue
        guard rssiValue != 127 else { return }

        if let index = discoveredDevices.firstIndex(where: { $0.uuid == peripheral.identifier }) {
            discoveredDevices[index].rssi = rssiValue
            discoveredDevices[index].advertisementData = advertisementData
        } else {
            let device = BLEDeviceInfo(peripheral: peripheral, rssi: rssiValue, advertisementData: advertisementData)
            discoveredDevices.append(device)
        }
        discoveredDevices.sort { $0.rssi > $1.rssi }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let uuid = peripheral.identifier
        connectedPeripherals[uuid] = peripheral
        connectionStates[uuid] = .connected
        // サービス・キャラクタリスティックを検出
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let uuid = peripheral.identifier
        let msg = error?.localizedDescription ?? "接続に失敗しました"
        connectionStates[uuid] = .failed(msg)
        connectedPeripherals.removeValue(forKey: uuid)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let uuid = peripheral.identifier
        connectionStates[uuid] = .disconnected
        connectedPeripherals.removeValue(forKey: uuid)
        discoveredServices.removeValue(forKey: uuid)
    }
}

// MARK: - CBPeripheralDelegate

extension BLEScanManager: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services else { return }
        discoveredServices[peripheral.identifier] = services
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // CBService オブジェクトは参照型なので characteristics が更新されたタイミングで再パブリッシュ
        if let services = peripheral.services {
            discoveredServices[peripheral.identifier] = services
        }
    }
}
