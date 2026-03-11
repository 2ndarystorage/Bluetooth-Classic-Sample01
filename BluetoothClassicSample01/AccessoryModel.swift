import Foundation
import ExternalAccessory
import CoreBluetooth

struct AccessoryInfo: Identifiable {
    let id: UUID = UUID()
    let accessory: EAAccessory

    var name: String { accessory.name }
    var manufacturer: String { accessory.manufacturer }
    var modelNumber: String { accessory.modelNumber }
    var serialNumber: String { accessory.serialNumber }
    var firmwareRevision: String { accessory.firmwareRevision }
    var hardwareRevision: String { accessory.hardwareRevision }
    var protocols: [String] { accessory.protocolStrings }
    var connectionID: Int { accessory.connectionID }
    var isConnected: Bool { accessory.isConnected }
}

// MARK: - BLE Device Model

struct BLEDeviceInfo: Identifiable {
    let id = UUID()
    let peripheral: CBPeripheral
    var rssi: Int
    var advertisementData: [String: Any]

    var uuid: UUID { peripheral.identifier }
    var name: String { peripheral.name ?? "名称不明" }
    var localName: String? { advertisementData[CBAdvertisementDataLocalNameKey] as? String }
    var displayName: String { localName ?? name }
    var isConnectable: Bool { (advertisementData[CBAdvertisementDataIsConnectable] as? Bool) ?? false }
    var serviceUUIDs: [CBUUID] { (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]) ?? [] }
    var rssiText: String { "\(rssi) dBm" }

    var signalStrength: SignalStrength {
        switch rssi {
        case -50...Int.max:        return .excellent
        case -70 ... -51:          return .good
        case -90 ... -71:          return .fair
        default:                   return .poor
        }
    }

    enum SignalStrength {
        case excellent, good, fair, poor
        var label: String {
            switch self {
            case .excellent: return "強"
            case .good:      return "普通"
            case .fair:      return "弱"
            case .poor:      return "非常に弱"
            }
        }
    }
}

// MARK: - BLE Connection State

enum BLEConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case failed(String)

    static func == (lhs: BLEConnectionState, rhs: BLEConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected),
             (.connecting, .connecting),
             (.connected, .connected),
             (.disconnecting, .disconnecting): return true
        case (.failed(let a), .failed(let b)): return a == b
        default: return false
        }
    }

    var label: String {
        switch self {
        case .disconnected:       return "未接続"
        case .connecting:         return "接続中..."
        case .connected:          return "接続済み"
        case .disconnecting:      return "切断中..."
        case .failed(let msg):    return "失敗: \(msg)"
        }
    }

    var isInProgress: Bool {
        switch self {
        case .connecting, .disconnecting: return true
        default: return false
        }
    }
}

// MARK: - Message Model

struct Message: Identifiable {
    let id: UUID = UUID()
    let content: String
    let timestamp: Date
    let isSent: Bool

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}
