import SwiftUI
import CoreBluetooth

struct BLEConnectionView: View {
    let device: BLEDeviceInfo
    @ObservedObject var bleManager: BLEScanManager
    @Environment(\.dismiss) private var dismiss

    private var connectionState: BLEConnectionState {
        bleManager.connectionStates[device.uuid] ?? .disconnected
    }

    private var services: [CBService] {
        bleManager.discoveredServices[device.uuid] ?? []
    }

    var body: some View {
        List {
            deviceInfoSection
            servicesSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(device.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                disconnectButton
            }
        }
        .onChange(of: connectionState) { newState in
            if case .disconnected = newState {
                dismiss()
            }
        }
    }

    // MARK: - Sections

    private var deviceInfoSection: some View {
        Section(header: Text("デバイス情報")) {
            LabeledContent("名前", value: device.displayName)
            LabeledContent("UUID") {
                Text(device.uuid.uuidString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            LabeledContent("RSSI", value: device.rssiText)
            LabeledContent("接続状態") {
                HStack(spacing: 5) {
                    Circle()
                        .fill(stateColor)
                        .frame(width: 8, height: 8)
                    Text(connectionState.label)
                        .foregroundColor(stateColor)
                        .font(.callout)
                    if connectionState.isInProgress {
                        ProgressView().scaleEffect(0.7)
                    }
                }
            }
        }
    }

    private var servicesSection: some View {
        Section(
            header: Text("サービス"),
            footer: services.isEmpty && connectionState == .connected
                ? Text("サービスを検出中...") : nil
        ) {
            if services.isEmpty {
                if connectionState == .connected {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("サービスを検出中...")
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                ForEach(services, id: \.uuid) { service in
                    ServiceDisclosureRow(service: service)
                }
            }
        }
    }

    // MARK: - Toolbar

    private var disconnectButton: some View {
        Button("切断") {
            bleManager.disconnectByUUID(device.uuid)
        }
        .foregroundColor(.red)
        .disabled(connectionState.isInProgress)
    }

    // MARK: - Helpers

    private var stateColor: Color {
        switch connectionState {
        case .connected:                  return .green
        case .connecting, .disconnecting: return .orange
        case .disconnected:               return .gray
        case .failed:                     return .red
        }
    }
}

// MARK: - ServiceDisclosureRow

struct ServiceDisclosureRow: View {
    let service: CBService
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            characteristicsContent
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(serviceDisplayName(service.uuid))
                    .font(.callout).fontWeight(.medium)
                Text(service.uuid.uuidString)
                    .font(.caption2).foregroundColor(.secondary)
                if let count = service.characteristics?.count {
                    Text("キャラクタリスティック: \(count) 件")
                        .font(.caption2).foregroundColor(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var characteristicsContent: some View {
        if let characteristics = service.characteristics, !characteristics.isEmpty {
            ForEach(characteristics, id: \.uuid) { characteristic in
                CharacteristicRow(characteristic: characteristic)
            }
        } else {
            Text("キャラクタリスティックなし")
                .font(.caption).foregroundColor(.secondary)
                .padding(.leading, 8)
        }
    }

    private func serviceDisplayName(_ uuid: CBUUID) -> String {
        let key = uuid.uuidString.uppercased()
        let knownServices: [String: String] = [
            "1800": "Generic Access",
            "1801": "Generic Attribute",
            "180A": "Device Information",
            "180D": "Heart Rate",
            "180F": "Battery Service",
            "1810": "Blood Pressure",
            "1816": "Cycling Speed and Cadence",
            "1818": "Cycling Power",
            "181C": "User Data",
            "FFF0": "Custom Service (FFF0)",
            "FFE0": "Custom Service (FFE0)",
        ]
        return knownServices[key] ?? uuid.uuidString
    }
}

// MARK: - CharacteristicRow

struct CharacteristicRow: View {
    let characteristic: CBCharacteristic

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(characteristic.uuid.uuidString)
                .font(.caption).fontWeight(.medium)

            let props = characteristicProperties(characteristic.properties)
            if !props.isEmpty {
                Text(props.joined(separator: " · "))
                    .font(.caption2).foregroundColor(.blue)
            }

            if let value = characteristic.value, !value.isEmpty {
                Text(value.map { String(format: "%02X", $0) }.joined(separator: " "))
                    .font(.caption2.monospaced()).foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.leading, 12)
        .padding(.vertical, 2)
    }

    private func characteristicProperties(_ props: CBCharacteristicProperties) -> [String] {
        var result: [String] = []
        if props.contains(.broadcast)           { result.append("ブロードキャスト") }
        if props.contains(.read)                { result.append("読み取り") }
        if props.contains(.writeWithoutResponse){ result.append("書き込み(応答なし)") }
        if props.contains(.write)               { result.append("書き込み") }
        if props.contains(.notify)              { result.append("通知") }
        if props.contains(.indicate)            { result.append("インジケート") }
        if props.contains(.authenticatedSignedWrites) { result.append("署名付き書き込み") }
        return result
    }
}
