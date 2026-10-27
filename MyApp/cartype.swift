
//
//  cartype.swift
//  MyApp
//
//  Created by may.mohammed on 16/05/1448 AH.
//
import SwiftUI

struct ContentView: View {
    let carBrands = [
        ("تويوتا", "Image"),
        ("شانجان", "Image 1"),
        ("هافال", "Image 2")
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

            VStack(alignment: .leading, spacing: 0) {

                Text("اختر شركة سيارتك:")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 105)
                    .padding(.horizontal, 4)

                // البطاقات
                VStack(spacing: 28) {
                    ForEach(carBrands, id: \.0) { brand in
                        BrandCard(name: brand.0, imageName: brand.1) {
                            print("تم اختيار: \(brand.0)")
                        }
                    }
                }
                .padding(.top, 24)

                VStack(spacing: 8) {
                    Text("لم تجد شركة سيارتك؟")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)

                    Text("قد لا تكون مدعومة حاليًا، ونعمل على\nإضافة المزيد من الشركات في\nالتحديثات القادمة.")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 50)

                Spacer()
            }
            .padding(.horizontal, 22)
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

struct BrandCard: View {
    let name: String
    let imageName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 22) {
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
