import Foundation
import ExternalAccessory

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
