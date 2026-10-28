import SwiftUI

@main
struct MyApp: App {

    @StateObject private var bluetoothManager: BluetoothManager
    @StateObject private var obdService: OBDService


    init() {

        let bluetoothManager = BluetoothManager()

        _bluetoothManager = StateObject(
            wrappedValue: bluetoothManager
        )

        _obdService = StateObject(
            wrappedValue: OBDService(
                bluetoothManager: bluetoothManager
            )
        )
    }


    var body: some Scene {

        WindowGroup {

            BluetoothFlowView(
                bluetoothManager: bluetoothManager,
                obdService: obdService,
                carName: "Toyota Corolla",
                isDemoMode: true,
                
                onCancel: {

                    print("Bluetooth flow cancelled")
                },
                onConnected: {

                    print("OBD connection ready")

                    print(
                        obdService.vehicleData
                    )
                }
            )
        }
    }
}
