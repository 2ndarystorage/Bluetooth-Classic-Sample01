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

## Program Summary
- iOS SwiftUI sample with two tabs: Bluetooth Classic (ExternalAccessory/MFi) and BLE scanning via CoreBluetooth.
- Classic tab opens an `EASession` for a selected accessory/protocol and sends/receives stream data.
- BLE tab scans, lists RSSI, connects/disconnects, and discovers services/characteristics.

## How to Use
- Open `BluetoothClassicSample01.xcodeproj` in Xcode and run on a physical iOS device (Bluetooth/ExternalAccessory are device-only). Not verified.
- Classic: add your accessory protocol to `BluetoothClassicSample01/Info.plist` (`UISupportedExternalAccessoryProtocols`), connect the MFi accessory, select it in the Classic tab, then send messages.
- BLE: open the BLE tab, tap the scan button, and connect to a device to view services/characteristics.

## Completion Status
- Partial: sample-level implementation with basic scan/connect and Classic stream I/O; limited error handling and no production hardening/tests.

## Program Summary
- iOS SwiftUI sample app with two tabs: Bluetooth Classic (ExternalAccessory/MFi) and BLE scanning/connection via CoreBluetooth.
- Classic flow: list connected accessories, pick protocol, open `EASession`, send/receive stream messages.
- BLE flow: scan, show RSSI/connectable state, connect/disconnect, and list discovered services/characteristics.

## How to Use
- Open `BluetoothClassicSample01.xcodeproj` in Xcode and run on a physical iOS device (Bluetooth/ExternalAccessory are device-only). Not verified.
- Classic: add your accessory protocol to `BluetoothClassicSample01/Info.plist` under `UISupportedExternalAccessoryProtocols`, connect an MFi accessory, select it, then open the session and send messages.
- BLE: open the BLE tab, start scanning, connect to a device, and view services/characteristics.

## Completion Status
- Partial: sample-level implementation with basic Classic session I/O and BLE scan/connect/discovery; minimal error handling and no tests or production hardening noted.

## Program Summary
- iOS SwiftUI sample app with two tabs: Bluetooth Classic (ExternalAccessory/MFi) and BLE scanning/connection (CoreBluetooth).
- Classic: lists connected accessories, lets you pick a protocol, opens an `EASession`, and sends/receives stream data.
- BLE: scans for peripherals, shows RSSI/connection state, connects/disconnects, and discovers services/characteristics.

## How to Use
- Open `BluetoothClassicSample01.xcodeproj` in Xcode and run on a physical iOS device (Bluetooth/ExternalAccessory are device-only). Not verified.
- Classic: add your accessory protocol to `BluetoothClassicSample01/Info.plist` under `UISupportedExternalAccessoryProtocols`, connect an MFi accessory, select it, choose a protocol, then open the session and send messages.
- BLE: open the BLE tab, start scanning, connect to a device, and view its services/characteristics.

## Completion Status
- Partial: sample-level flows for Classic session I/O and BLE scan/connect/discovery exist, but there are no tests or production hardening and error handling is minimal.

## Program Summary
- iOS SwiftUI sample app with two tabs: Bluetooth Classic (ExternalAccessory/MFi) communication and BLE scanning/connection via CoreBluetooth.
- Classic flow lists connected accessories, lets you choose a protocol, opens an `EASession`, and sends/receives stream messages.
- BLE flow scans nearby peripherals, shows RSSI/connection state, connects/disconnects, and lists discovered services/characteristics.

## How to Use
- Open `BluetoothClassicSample01.xcodeproj` in Xcode and run on a physical iOS device (Bluetooth/ExternalAccessory are device-only). Not verified.
- Classic: add your accessory protocol string to `BluetoothClassicSample01/Info.plist` under `UISupportedExternalAccessoryProtocols`, connect an MFi accessory, select it, choose a protocol, then open the session and send messages.
- BLE: open the BLE tab, tap scan, connect to a device, and view its services/characteristics.

## Completion Status
- Partial: sample-level implementation with basic Classic stream I/O and BLE scan/connect/service discovery; minimal error handling and no tests or production hardening noted.

## Program Summary
- iOS SwiftUI sample app with two tabs: Bluetooth Classic (ExternalAccessory/MFi) and BLE scanning/connection (CoreBluetooth).
- Classic: lists connected MFi accessories, opens an `EASession` for a selected protocol, sends/receives stream data.
- BLE: scans nearby peripherals, shows RSSI/connectability, connects/disconnects, and discovers services/characteristics.

## How to Use
- Open `BluetoothClassicSample01.xcodeproj` in Xcode and run on a physical iOS device (Bluetooth/ExternalAccessory are device-only). Not verified.
- Classic: add your accessory protocol string to `BluetoothClassicSample01/Info.plist` under `UISupportedExternalAccessoryProtocols`, connect an MFi accessory, select it, then open a session and send messages.
- BLE: open the BLE tab, start scanning, connect to a device, and view services/characteristics.

## Completion Status
- Partial: sample-level flows for Classic session I/O and BLE scan/connect/discovery exist, but error handling is minimal and no tests or production hardening are present.
