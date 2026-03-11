## Program Summary
- iOS SwiftUI sample app with two tabs: Bluetooth Classic (ExternalAccessory/MFi) and BLE scanning.
- Bluetooth Classic tab lists connected MFi accessories, lets you pick a protocol string, opens an `EASession`, and sends/receives messages.
- BLE tab scans nearby peripherals, shows RSSI and connectability, allows connect/disconnect, and lists discovered services/characteristics.

## How to Use
- Open the Xcode project and run on a physical iOS device (Bluetooth and ExternalAccessory are device-only). Not verified.
- For Bluetooth Classic:
- Add your accessory protocol string to `UISupportedExternalAccessoryProtocols` in `BluetoothClassicSample01/Info.plist`.
- Connect a MFi accessory, select it in the Classic tab, choose a protocol, then use the message input to send.
- For BLE:
- Go to the BLE tab, tap "スキャン開始", and connect to a device to view services/characteristics.

## Completion Status
- Partial: core UI flows exist for Classic session open/send/receive and BLE scan/connect/service discovery, but it is a sample app without production hardening or comprehensive error handling.
