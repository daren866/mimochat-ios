import SwiftUI

struct ContentView: View {
    @State private var inputText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("MiMo2.5-Pro")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "gear")
                        .font(.title)
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 20)
            
            Spacer()
            
            Text("有什么需要帮忙的？")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .padding(.bottom, 30)
            
            HStack(spacing: 0) {
                TextField("请输入文本，支持多行", text: $inputText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(0)
                
                Button(action: {}) {
                    Text("发送")
                        .font(.title2)
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(0)
                }
            }
            .border(Color.black, width: 1)
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(Color.white)
        .edgesIgnoringSafeArea(.all)
    }
}
