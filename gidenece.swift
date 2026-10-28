import SwiftUI
import Playgrounds

struct coontentView: View {
    var body: some View {
        ZStack  {LinearGradient(
            stops: [
                .init(color: Color(red: 0.14, green: 0.17, blue: 0.14), location: 0.0),
                .init(color: Color(red: 0.17, green: 0.22, blue: 0.18), location: 0.45),
                .init(color: Color(red: 0.10, green: 0.12, blue: 0.11), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
            
            
            
            VStack(spacing:16){
                HStack{
                    Spacer()
                    Button("تخطي"){
                        
                    }
                    .foregroundStyle(.white)
                }
                .padding(.horizontal)
                Spacer()
                Image(.offlineBluetoothCarLink)
                    .resizable()
                    .frame(width: 220,height:180)
                    .padding(.top, -50)
                
                Section{Text("محوّل صغير يُركَّب أسفل المقود، ويرسل القراءات إلى هاتفك عبر البلوتوث.")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }header: {Text(" يعمل دون إنترنت ")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                    
                        .frame(maxWidth: .infinity,alignment: .center)
                        .multilineTextAlignment(.center)
                    
                    
                }
                
                Spacer()
                
                
                
                
                
                
                
                HStack {
                    
                    
                    
                    
                    Button {
                        
                    } label: {
                        Text("ابدأ")
                        
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(width: 52, height: 52)
                            .background(Color.white)
                            .clipShape(Circle())
                        
                    }
                    Spacer()
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
                HStack(spacing: 8) {
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 8, height: 8)
                }
                
            }
            
        }
    }
}

#Preview {
    coontentView()
}

#Playground {
    _ = 1 + 2
}

