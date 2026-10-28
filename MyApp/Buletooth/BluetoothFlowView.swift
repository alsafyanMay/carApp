import SwiftUI

struct BluetoothFlowView: View {
    
    // MARK: - Dependencies
    
    @ObservedObject var bluetoothManager:
    BluetoothManager
    
    @ObservedObject var obdService:
    OBDService
    
    let carName: String
    
    let isDemoMode: Bool
    
    var onCancel: () -> Void = {}
    var onConnected: () -> Void = {}
    
    
    // MARK: - Local UI State
    
    @State private var showPermissionPopup = true
    
    @State private var didFinishConnection = false
    
    
    @State private var demoPopupState: BluetoothPopupState = .permission
    
    // MARK: - View
    var body: some View {
        
        ZStack {
            
            Color(
                red: 0.05,
                green: 0.10,
                blue: 0.09
            )
            .ignoresSafeArea()
            
            if isDemoMode {
                
                demoFlow
                
            } else {
                
                realBluetoothFlow
            }
        }
        .onChange(of: bluetoothManager.state) { _, newState in
            
            guard !isDemoMode else {
                return
            }
            
            handleBluetoothState(newState)
        }
        .onChange(of: obdService.state) { _, newState in
            
            guard !isDemoMode else {
                return
            }
            
            handleOBDState(newState)
        }
    }}
    
    
    // MARK: - Demo Flow
    
    private extension BluetoothFlowView {
        
        @ViewBuilder
        var demoFlow: some View {
            
            switch demoPopupState {
                
            case .permission:
                
                BluetoothPopupView(
                    state: .permission,
                    onAllow: startDemoConnection,
                    onDeny: cancelFlow
                )
                
                
            case .connecting:
                
                BluetoothPopupView(
                    state: .connecting
                )
                
                
            case .connected(let carName):
                
                BluetoothPopupView(
                    state: .connected(
                        carName: carName
                    )
                )
                
                
            case .failed(let message):
                
                BluetoothPopupView(
                    state: .failed(
                        message: message
                    ),
                    onRetry: startDemoConnection
                )
            }
        }
    }
    
    
    // MARK: - Real Bluetooth Flow
    
    private extension BluetoothFlowView {
        
        @ViewBuilder
        var realBluetoothFlow: some View {
            
            if showPermissionPopup {
                
                BluetoothPopupView(
                    state: .permission,
                    onAllow: allowBluetooth,
                    onDeny: cancelFlow
                )
                
            } else {
                
                connectionPopup
            }
        }
    }
    
    // MARK: - Popup State
    
    private extension BluetoothFlowView {
        
        @ViewBuilder
        var connectionPopup: some View {
            
            switch bluetoothManager.state {
                
            case .idle,
                    .waitingForPermission,
                    .scanning,
                    .connecting:
                
                BluetoothPopupView(
                    state: .connecting
                )
                
                
            case .connected:
                
                switch obdService.state {
                    
                case .ready:
                    
                    BluetoothPopupView(
                        state: .connected(
                            carName: carName
                        )
                    )
                    
                    
                case .failed(let message):
                    
                    BluetoothPopupView(
                        state: .failed(
                            message: message
                        ),
                        onRetry: retryConnection
                    )
                    
                    
                case .idle,
                        .initializing:
                    
                    BluetoothPopupView(
                        state: .connecting
                    )
                }
                
                
            case .bluetoothOff:
                
                BluetoothPopupView(
                    state: .failed(
                        message:
                            "البلوتوث مغلق. شغّله من إعدادات الجهاز ثم حاول مرة أخرى."
                    ),
                    onRetry: retryConnection
                )
                
                
            case .failed(let message):
                
                BluetoothPopupView(
                    state: .failed(
                        message: arabicMessage(
                            for: message
                        )
                    ),
                    onRetry: retryConnection
                )
            }
        }
    }
    
    
    // MARK: - Actions
    
    private extension BluetoothFlowView {
        
        
        func startDemoConnection() {
            
            demoPopupState = .connecting
            
            Task {
                
                // Simulate connection time.
                try? await Task.sleep(
                    for: .seconds(2)
                )
                
                await MainActor.run {
                    
                    demoPopupState = .connected(
                        carName: carName
                    )
                }
                
                // Keep the success popup visible briefly.
                try? await Task.sleep(
                    for: .seconds(1.2)
                )
                
                await MainActor.run {
                    
                    onConnected()
                }
            }
        }
        
        
        
        func allowBluetooth() {
            
            // Hide our explanation popup.
            showPermissionPopup = false
            
            // Start CoreBluetooth.
            bluetoothManager.start()
        }
        
        
        func cancelFlow() {
            
            obdService.stopSession()
            bluetoothManager.disconnect()
            
            onCancel()
        }
        
        
        func retryConnection() {
            
            didFinishConnection = false
            
            obdService.stopSession()
            
            bluetoothManager.retry()
        }
        
        
        func handleBluetoothState(
            _ state: BluetoothConnectionState
        ) {
            
            guard state == .connected else {
                return
            }
            
            // Bluetooth is ready.
            // Start the OBD initialization process.
            obdService.startSession()
        }
        
        
        func handleOBDState(
            _ state: OBDSessionState
        ) {
            
            guard state == .ready else {
                return
            }
            
            guard !didFinishConnection else {
                return
            }
            
            didFinishConnection = true
            
            // Keep the success popup visible briefly,
            // then move automatically to the Dashboard.
            Task {
                
                try? await Task.sleep(
                    for: .seconds(1.2)
                )
                
                await MainActor.run {
                    
                    onConnected()
                }
            }
        }
        
        
        func arabicMessage(
            for message: String
        ) -> String {
            
            switch message {
                
            case "Bluetooth permission was denied.":
                
                return
                "تم رفض صلاحية البلوتوث. يمكنك السماح بها من إعدادات الجهاز."
                
                
            case "Unable to connect to the OBD adapter.":
                
                return
                "لم نتمكن من الاتصال بجهاز السيارة. تأكد من تركيب الجهاز وتشغيل السيارة."
                
                
            case "The OBD adapter was disconnected.":
                
                return
                "انقطع الاتصال بجهاز السيارة. تأكد من بقائك بالقرب من السيارة."
                
                
            case "Bluetooth is not supported on this device.":
                
                return
                "هذا الجهاز لا يدعم اتصال البلوتوث المطلوب."
                
                
            default:
                
                return
                "تعذر إكمال الاتصال. تأكد من تشغيل السيارة والبلوتوث ثم حاول مرة أخرى."
            }
        }
    }
    
    
    #Preview("Bluetooth Demo Flow") {
        
        let bluetoothManager = BluetoothManager()
        
        let obdService = OBDService(
            bluetoothManager: bluetoothManager
        )
        
        BluetoothFlowView(
            bluetoothManager: bluetoothManager,
            obdService: obdService,
            carName: "MyCar22",
            isDemoMode: true
        )
    }
    
   /* #Preview("Bluetooth Demo Flow") {

        let bluetoothManager = BluetoothManager()

        let obdService = OBDService(
            bluetoothManager: bluetoothManager
        )

        BluetoothFlowView(
            bluetoothManager: bluetoothManager,
            obdService: obdService,
            carName: "MyCar22",
            isDemoMode: true
        )
    }*/
