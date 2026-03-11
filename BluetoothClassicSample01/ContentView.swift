import SwiftUI

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothClassicManager()

    var body: some View {
        TabView {
            NavigationView {
                AccessoryListView()
                    .environmentObject(bluetoothManager)
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Classic", systemImage: "cable.connector")
            }

            NavigationView {
                BLEScanView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("BLE スキャン", systemImage: "dot.radiowaves.left.and.right")
            }
        }
    }
}
