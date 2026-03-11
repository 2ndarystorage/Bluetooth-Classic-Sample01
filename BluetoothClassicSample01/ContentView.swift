import SwiftUI

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothClassicManager()

    var body: some View {
        NavigationView {
            AccessoryListView()
                .environmentObject(bluetoothManager)
        }
        .navigationViewStyle(.stack)
    }
}
