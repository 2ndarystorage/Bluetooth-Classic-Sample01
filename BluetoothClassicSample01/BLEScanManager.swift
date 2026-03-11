import Foundation
import CoreBluetooth

/// CoreBluetooth を使った BLE デバイススキャンマネージャー
///
/// iOS は Bluetooth Classic デバイスを任意にスキャンできないため、
/// BLE (Bluetooth Low Energy) デバイスのスキャンを提供します。
class BLEScanManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var discoveredDevices: [BLEDeviceInfo] = []
    @Published var isScanning: Bool = false
    @Published var state: CBManagerState = .unknown
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private var centralManager: CBCentralManager!
    private var scanTimer: Timer?

    // MARK: - Init

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: - Scan Control

    /// スキャンを開始する
    /// - Parameter duration: スキャン継続時間（秒）。0 なら手動停止まで継続
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

    /// スキャンを停止する
    func stopScan() {
        centralManager.stopScan()
        scanTimer?.invalidate()
        scanTimer = nil
        isScanning = false
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
        guard rssiValue != 127 else { return } // 127 = 測定不可

        if let index = discoveredDevices.firstIndex(where: { $0.uuid == peripheral.identifier }) {
            discoveredDevices[index].rssi = rssiValue
            discoveredDevices[index].advertisementData = advertisementData
        } else {
            let device = BLEDeviceInfo(peripheral: peripheral, rssi: rssiValue, advertisementData: advertisementData)
            discoveredDevices.append(device)
        }
        // RSSI 降順（電波強度が高い順）でソート
        discoveredDevices.sort { $0.rssi > $1.rssi }
    }
}
