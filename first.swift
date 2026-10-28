import SwiftUI
import Playgrounds

    struct splash: View {
        
        var body: some View {
            
            NavigationStack{
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
                        NavigationLink(destination: ContentView()) {
                        Text("تخطي")
                            
                        }
                        .foregroundStyle(.white)
                    }
                    .padding(.horizontal)
                    
                    
                    Spacer()
                    Image(.mirroredCarWithFuelAndTemperatureCardsCopy)
                        .resizable()
                        .frame(width: 220,height:180)
                        .padding(.top, -50)
                    
                    Section{Text("نعرض لك أهم قراءات سيارتك، ونشرح ما تعنيه وما الذي تفعله بعدها بلغة واضحة.")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                    }header: {Text("افهم سيارتك دون خبره ميكانيكه ")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                        
                            .frame(maxWidth: .infinity,alignment: .center)
                            .multilineTextAlignment(.center)
                        
                        
                    }
                    
                    Spacer()
                    
                    
                    
                    
                    
                    HStack {
                        
                        
                        
                        // زر الانتقال للصفحة التالية
                     
                            
                        NavigationLink(destination: coontentView()) {
                            Image(systemName: "arrow.left")
                                .foregroundColor(.black)
                                .frame(width: 55, height: 55)
                                .background(Color.white)
                                .clipShape(Circle())
                               
                        }
                      
                        Spacer()
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                    
                    
                    HStack(spacing: 8) {
                        NavigationLink(destination: coontentView()) {
                            Circle()
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 8, height: 8)
                        }
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                        
                        
                        
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}
#Preview {
    splash()
}

#Playground {
    _ = 1 + 2
}
