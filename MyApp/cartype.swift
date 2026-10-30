
//
//  cartype.swift
//  MyApp
//
//  Created by may.mohammed on 16/05/1448 AH.
//
import SwiftUI

struct ContentView: View {
    // MARK: - Shared Connection Owners

    @StateObject private var bluetoothManager: BluetoothManager
    @StateObject private var obdService: OBDService
    @State private var selectedBrand: String?
    @State private var savedVehicle = SavedVehicle.load()
    // هل الداش بورد ظاهر؟ (يصير true بعد ما ينجح الاتصال)
      @State private var showDashboard = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let manager = BluetoothManager()
        _bluetoothManager = StateObject(wrappedValue: manager)
        _obdService = StateObject(wrappedValue: OBDService(bluetoothManager: manager))
    }

    let carBrands = [
        ("تويوتا", "Image"),
        ("شانجان", "Image 1"),
        ("هافال", "Image 2"),
        ("شركة أخرى", "")
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.14, green: 0.17, blue: 0.14), location: 0.0),
                    .init(color: Color(red: 0.17, green: 0.22, blue: 0.18), location: 0.45),
                    .init(color: Color(red: 0.10, green: 0.12, blue: 0.11), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            GeometryReader { _ in
            ViewThatFits(in: .vertical) {
                brandSelection
                ScrollView { brandSelection }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom) {
            if selectedBrand == nil, let vehicle = savedVehicle {
                savedConnectionCard(vehicle)
            }
        }
        .blur(radius: selectedBrand == nil ? 0 : 5)
        .allowsHitTesting(selectedBrand == nil)
        .overlay {
            if let brand = selectedBrand {
                BluetoothFlowView(
                    bluetoothManager: bluetoothManager,
                    obdService: obdService,
                    carName: brand,
                    isDemoMode: false,
                    onCancel: { selectedBrand = nil },
                    onConnected: {
                        savedVehicle = SavedVehicle.load()
                        selectedBrand = nil
                        // Dashboard file is not supplied. Replace this callback with its route.
                        showDashboard = true
                        // The success popup must never imply that a missing dashboard exists.
                    }
                )
            }
        }
        .onChange(of: scenePhase) { _, phase in
                    if phase == .background {
                        obdService.stopSession()
                        bluetoothManager.disconnect()
                    }
                }
                .environment(\.layoutDirection, .rightToLeft)
                // الداش بورد يغطي الشاشة كاملة بعد الاتصال
        // الداش بورد يغطي الشاشة كاملة بعد الاتصال
        .fullScreenCover(isPresented: $showDashboard) {
            // نرسل القراءات الحية من جهاز الـ OBD
            DashboardView(
                coolantTemp: obdService.vehicleData.coolantTemperature,
                fuelLevel: obdService.vehicleData.fuelLevel,
                batteryVoltage: obdService.vehicleData.batteryVoltage,
                isConnected: obdService.state == .ready,
                // إعادة الاتصال: نرجع لصفحة اختيار السيارة
                onReconnect: { showDashboard = false }
            )
        }
            }

    private var brandSelection: some View {
            VStack(alignment: .leading, spacing: 0) {

                Text("اختر شركة سيارتك:")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 28)
                    .padding(.horizontal, 4)

                // البطاقات
                VStack(spacing: 16) {
                    ForEach(carBrands, id: \.0) { brand in
                        BrandCard(name: brand.0, imageName: brand.1) {
                            beginConnection(for: brand.0)
                        }
                    }
                }
                .padding(.top, 24)

                VStack(spacing: 8) {
                    Text("هل سيارتي مدعومة؟")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)

                    Text("توفّر القراءات يعتمد على سيارتك\nوجهاز LELink المستخدم، وليس الشركة وحدها.")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 24)

            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 22)
            .padding(.bottom, 24)
    }

    // MARK: - Vehicle Profile and Connection Status

    private var isConnected: Bool {
        bluetoothManager.state == .connected && obdService.state == .ready
    }

    private func beginConnection(for brand: String) {
        if savedVehicle?.brand != brand {
            obdService.stopSession()
            bluetoothManager.disconnect()
        }
        selectedBrand = brand
    }

    private func savedConnectionCard(_ vehicle: SavedVehicle) -> some View {
        HStack(spacing: 12) {
            Circle().fill(isConnected ? Color.green : Color.white.opacity(0.35))
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(vehicle.brand) — \(isConnected ? "متصل" : "غير متصل")")
                    .font(.subheadline.bold()).foregroundStyle(.white)
                Text(vehicle.deviceName).font(.caption)
                    .foregroundStyle(Color.white.opacity(0.55))
            }
            Spacer(minLength: 0)
            Button(isConnected ? "حالة الاتصال" : "إعادة الاتصال") {
                selectedBrand = vehicle.brand
            }
            .font(.subheadline).foregroundStyle(.white)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.black.opacity(0.28)))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08)))
        .padding(.horizontal, 22).padding(.bottom, 12)
    }
}

struct BrandCard: View {
    let name: String
    let imageName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 22) {
                if imageName.isEmpty {
                    Image(systemName: "car.side.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.white.opacity(0.72))
                        .frame(width: 68, height: 68)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15)))
                } else {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 68, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
                }

                Text(name)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))

                Spacer()

                Image(systemName: "chevron.forward")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.trailing, 10)
            }
            .padding(.leading, 14)
            .padding(.trailing, 14)
            .frame(height: 92)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.28))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
            )
            .contentShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
