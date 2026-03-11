import SwiftUI

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothClassicManager()

    var body: some View {
        TabView {
            NavigationStack {
                AccessoryListView()
                    .environmentObject(bluetoothManager)
            }
            .tabItem {
                Label("Classic", systemImage: "cable.connector")
            }

            NavigationStack {
                BLEScanView()
            }
            .tabItem {
                Label("BLE スキャン", systemImage: "dot.radiowaves.left.and.right")
            }
        }
    }
}
