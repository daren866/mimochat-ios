import SwiftUI

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct ContentView: View {
    @State private var inputText = ""
    @State private var messages: [Message] = []
    @State private var showChat = false
    
    var body: some View {
        if showChat {
            ChatView(messages: $messages, inputText: $inputText)
        } else {
            WelcomeView(inputText: $inputText, onSend: sendMessage)
        }
    }
    
    private func sendMessage() {
        if !inputText.trimmingCharacters(in: .whitespaces).isEmpty {
            messages.append(Message(text: inputText, isUser: true))
            messages.append(Message(text: "你好有什么可以帮助的吗?", isUser: false))
            showChat = true
            inputText = ""
        }
    }
}

struct WelcomeView: View {
    @Binding var inputText: String
    let onSend: () -> Void
    
    var body: some View {
        ZStack {
            Color.white
                .edgesIgnoringSafeArea(.all)
            
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
            }
            
            VStack(spacing: 30) {
                Text("有什么需要帮忙的？")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                HStack(spacing: 0) {
                    TextField("请输入文本，支持多行", text: $inputText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(0)
                    
                    Button(action: {
                        if !inputText.trimmingCharacters(in: .whitespaces).isEmpty {
                            onSend()
                        }
                    }) {
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
            }
        }
    }
}

struct ChatView: View {
    @Binding var messages: [Message]
    @Binding var inputText: String
    
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
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            
            HStack(spacing: 0) {
                TextField("请输入文本，支持多行", text: $inputText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(0)
                
                Button(action: sendMessage) {
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
    }
    
    private func sendMessage() {
        if !inputText.trimmingCharacters(in: .whitespaces).isEmpty {
            messages.append(Message(text: inputText, isUser: true))
            messages.append(Message(text: "这是模拟回复", isUser: false))
            inputText = ""
        }
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                Text(message.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            } else {
                Text(message.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.black)
                    .cornerRadius(12)
                Spacer()
            }
        }
    }
}
