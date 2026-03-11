import SwiftUI
import ExternalAccessory

struct AccessoryListView: View {
    @EnvironmentObject var bluetoothManager: BluetoothClassicManager
    @State private var selectedForProtocol: AccessoryInfo?

    var body: some View {
        List {
            Section(header: Text("接続済みアクセサリ")) {
                if bluetoothManager.connectedAccessories.isEmpty {
                    emptyAccessoryView
                } else {
                    ForEach(bluetoothManager.connectedAccessories) { info in
                        AccessoryRow(accessoryInfo: info)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedForProtocol = info }
                    }
                }
            }

            Section(header: Text("使い方")) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("MFi認定アクセサリを iPhone に接続してください", systemImage: "cable.connector")
                    Label("Info.plist に UISupportedExternalAccessoryProtocols を追加", systemImage: "doc.badge.plus")
                    Label("アクセサリのプロトコル文字列をメーカーから入手してください", systemImage: "key.fill")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Bluetooth Classic")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    bluetoothManager.refreshAccessories()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .sheet(item: $selectedForProtocol) { info in
            ProtocolSelectionView(accessoryInfo: info)
                .environmentObject(bluetoothManager)
        }
        .alert("エラー",
               isPresented: Binding(
                   get: { bluetoothManager.errorMessage != nil },
                   set: { if !$0 { bluetoothManager.errorMessage = nil } }
               )) {
            Button("OK") { bluetoothManager.errorMessage = nil }
        } message: {
            Text(bluetoothManager.errorMessage ?? "")
        }
    }

    private var emptyAccessoryView: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "bluetooth.slash")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("アクセサリが見つかりません")
                    .foregroundColor(.secondary)
                Text("MFi 認定アクセサリを接続してください")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            Spacer()
        }
    }
}

// MARK: - AccessoryRow

struct AccessoryRow: View {
    let accessoryInfo: AccessoryInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "hifispeaker.fill")
                    .foregroundColor(.blue)
                Text(accessoryInfo.name.isEmpty ? "名称不明" : accessoryInfo.name)
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(accessoryInfo.isConnected ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
            }

            if !accessoryInfo.manufacturer.isEmpty {
                Text("メーカー: \(accessoryInfo.manufacturer)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if !accessoryInfo.modelNumber.isEmpty {
                Text("モデル: \(accessoryInfo.modelNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if !accessoryInfo.protocols.isEmpty {
                Text("プロトコル: \(accessoryInfo.protocols.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ProtocolSelectionView

struct ProtocolSelectionView: View {
    let accessoryInfo: AccessoryInfo
    @EnvironmentObject var bluetoothManager: BluetoothClassicManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProtocol: String?
    @State private var customProtocol: String = ""
    @State private var navigateToCommunication = false

    var body: some View {
        NavigationView {
            Form {
                accessoryInfoSection
                protocolListSection
                customProtocolSection
                connectSection
            }
            .navigationTitle("プロトコル選択")
            .navigationBarItems(leading: Button("キャンセル") { dismiss() })
            .background(
                NavigationLink(destination: CommunicationView()
                    .environmentObject(bluetoothManager),
                    isActive: $navigateToCommunication) { EmptyView() }
            )
        }
    }

    private var accessoryInfoSection: some View {
        Section(header: Text("アクセサリ情報")) {
            LabeledContent("名前", value: accessoryInfo.name)
            LabeledContent("メーカー", value: accessoryInfo.manufacturer)
            LabeledContent("モデル", value: accessoryInfo.modelNumber)
            LabeledContent("シリアル番号", value: accessoryInfo.serialNumber)
            LabeledContent("ファームウェア", value: accessoryInfo.firmwareRevision)
        }
    }

    private var protocolListSection: some View {
        Section(header: Text("利用可能なプロトコル")) {
            if accessoryInfo.protocols.isEmpty {
                Text("プロトコルが見つかりません")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(accessoryInfo.protocols, id: \.self) { proto in
                    HStack {
                        Text(proto)
                            .font(.callout)
                        Spacer()
                        if selectedProtocol == proto {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { selectedProtocol = proto }
                }
            }
        }
    }

    private var customProtocolSection: some View {
        Section(header: Text("カスタムプロトコル")) {
            TextField("例: com.example.myprotocol", text: $customProtocol)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            Button("このプロトコルを使用") {
                selectedProtocol = customProtocol
            }
            .disabled(customProtocol.isEmpty)
        }
    }

    private var connectSection: some View {
        Section {
            Button {
                guard let proto = selectedProtocol else { return }
                bluetoothManager.openSession(for: accessoryInfo, protocolString: proto)
                navigateToCommunication = true
            } label: {
                HStack {
                    Spacer()
                    Text("接続する")
                        .bold()
                    Spacer()
                }
            }
            .disabled(selectedProtocol == nil)
        }
    }
}
