import SwiftUI
import CoreBluetooth

struct BLEScanView: View {
    @StateObject private var bleManager = BLEScanManager()

    var body: some View {
        VStack(spacing: 0) {
            scanControlBar
            Divider()

            if bleManager.state == .poweredOff {
                bluetoothOffView
            } else if bleManager.state == .unauthorized {
                unauthorizedView
            } else {
                deviceListView
            }
        }
        .navigationTitle("BLE スキャン")
        .onDisappear { bleManager.stopScan() }
        .alert("エラー",
               isPresented: Binding(
                   get: { bleManager.errorMessage != nil },
                   set: { if !$0 { bleManager.errorMessage = nil } }
               )) {
            Button("OK") { bleManager.errorMessage = nil }
        } message: {
            Text(bleManager.errorMessage ?? "")
        }
    }

    // MARK: - Subviews

    private var scanControlBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if bleManager.isScanning {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(bleManager.isScanning ? "スキャン中..." : "スキャン停止")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                Text("\(bleManager.discoveredDevices.count) 台発見")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button {
                if bleManager.isScanning {
                    bleManager.stopScan()
                } else {
                    bleManager.startScan()
                }
            } label: {
                Text(bleManager.isScanning ? "停止" : "スキャン開始")
                    .frame(minWidth: 90)
            }
            .buttonStyle(.borderedProminent)
            .tint(bleManager.isScanning ? .red : .blue)
            .disabled(bleManager.state != .poweredOn && !bleManager.isScanning)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
    }

    private var deviceListView: some View {
        List {
            if bleManager.discoveredDevices.isEmpty {
                emptyView
            } else {
                Section(header: Text("発見したデバイス（RSSI 降順）")) {
                    ForEach(bleManager.discoveredDevices) { device in
                        BLEDeviceRow(device: device)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyView: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 44))
                    .foregroundColor(.secondary.opacity(0.4))
                Text(bleManager.isScanning ? "スキャン中..." : "「スキャン開始」を押してください")
                    .foregroundColor(.secondary)
                    .font(.callout)
                if !bleManager.isScanning {
                    Text("BLE デバイスを検出します")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 60)
            Spacer()
        }
        .listRowBackground(Color.clear)
    }

    private var bluetoothOffView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bluetooth.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Bluetooth がオフです")
                .font(.title2)
                .fontWeight(.medium)
            Text("設定 > Bluetooth からオンにしてください")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var unauthorizedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            Text("Bluetooth の許可が必要です")
                .font(.title2)
                .fontWeight(.medium)
            Text("設定 > プライバシーとセキュリティ > Bluetooth\nからこのアプリを許可してください")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - BLEDeviceRow

struct BLEDeviceRow: View {
    let device: BLEDeviceInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .foregroundColor(signalColor)
                    .frame(width: 20)

                Text(device.displayName)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                rssiBadge
            }

            HStack(spacing: 6) {
                Text(device.uuid.uuidString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            HStack(spacing: 8) {
                if device.isConnectable {
                    Label("接続可能", systemImage: "link")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                if !device.serviceUUIDs.isEmpty {
                    Text("サービス: \(device.serviceUUIDs.count) 件")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var rssiBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: signalSystemImage)
                .font(.caption)
                .foregroundColor(signalColor)
            Text(device.rssiText)
                .font(.caption)
                .foregroundColor(.secondary)
                .monospacedDigit()
        }
    }

    private var signalColor: Color {
        switch device.signalStrength {
        case .excellent: return .green
        case .good:      return .yellow
        case .fair:      return .orange
        case .poor:      return .red
        }
    }

    private var signalSystemImage: String {
        switch device.signalStrength {
        case .excellent: return "wifi"
        case .good:      return "wifi"
        case .fair:      return "wifi.exclamationmark"
        case .poor:      return "wifi.slash"
        }
    }
}
