import SwiftUI

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct ChatRecord: Identifiable {
    let id = UUID()
    let title: String
    let messages: [Message]
}

struct ContentView: View {
    @State private var inputText = ""
    @State private var messages: [Message] = []
    @State private var showChat = false
    @State private var showSettings = false
    @State private var showChatHistory = false
    @State private var mimoToken = ""
    @State private var chatRecords: [ChatRecord] = [
        ChatRecord(title: "芒果西瓜对抗", messages: []),
        ChatRecord(title: "芒果西瓜对抗", messages: []),
        ChatRecord(title: "芒果西瓜对抗", messages: []),
        ChatRecord(title: "芒果西瓜对抗", messages: []),
    ]
    
    var body: some View {
        if showChat {
            ChatView(
                messages: $messages,
                inputText: $inputText,
                showSettings: $showSettings,
                showChatHistory: $showChatHistory,
                mimoToken: $mimoToken,
                chatRecords: $chatRecords
            )
        } else {
            WelcomeView(
                inputText: $inputText,
                onSend: sendMessage,
                showSettings: $showSettings,
                showChatHistory: $showChatHistory,
                mimoToken: $mimoToken,
                chatRecords: $chatRecords
            )
        }
    }
    
    private func sendMessage() {
        if !inputText.trimmingCharacters(in: .whitespaces).isEmpty {
            messages.append(Message(text: inputText, isUser: true))
            messages.append(Message(text: "你好有什么可以帮助的吗?", isUser: false))
            chatRecords.insert(ChatRecord(title: inputText, messages: messages), at: 0)
            if chatRecords.count > 4 {
                chatRecords.removeLast()
            }
            showChat = true
            inputText = ""
        }
    }
}

struct WelcomeView: View {
    @Binding var inputText: String
    let onSend: () -> Void
    @Binding var showSettings: Bool
    @Binding var showChatHistory: Bool
    @Binding var mimoToken: String
    @Binding var chatRecords: [ChatRecord]
    
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
                    
                    Button(action: {
                        showChatHistory = true
                    }) {
                        Image(systemName: "doc.text")
                            .font(.title)
                            .foregroundColor(.black)
                    }
                    
                    Button(action: {
                        showSettings = true
                    }) {
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
            
            if showSettings {
                SettingsView(
                    showSettings: $showSettings,
                    mimoToken: $mimoToken
                )
            }
            
            if showChatHistory {
                ChatHistoryView(
                    showChatHistory: $showChatHistory,
                    chatRecords: $chatRecords
                )
            }
        }
    }
}

struct ChatView: View {
    @Binding var messages: [Message]
    @Binding var inputText: String
    @Binding var showSettings: Bool
    @Binding var showChatHistory: Bool
    @Binding var mimoToken: String
    @Binding var chatRecords: [ChatRecord]
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Text("MiMo2.5-Pro")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Button(action: {
                        showChatHistory = true
                    }) {
                        Image(systemName: "doc.text")
                            .font(.title)
                            .foregroundColor(.black)
                    }
                    
                    Button(action: {
                        showSettings = true
                    }) {
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
            
            if showSettings {
                SettingsView(
                    showSettings: $showSettings,
                    mimoToken: $mimoToken
                )
            }
            
            if showChatHistory {
                ChatHistoryView(
                    showChatHistory: $showChatHistory,
                    chatRecords: $chatRecords
                )
            }
        }
    }
    
    private func sendMessage() {
        if !inputText.trimmingCharacters(in: .whitespaces).isEmpty {
            messages.append(Message(text: inputText, isUser: true))
            messages.append(Message(text: "这是模拟回复", isUser: false))
            inputText = ""
        }
    }
}

struct SettingsView: View {
    @Binding var showSettings: Bool
    @Binding var mimoToken: String
    @State private var showTokenAlert = false
    @State private var tempToken = ""
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    showSettings = false
                }
            
            VStack(spacing: 0) {
                HStack {
                    Text("设置")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Button(action: {
                        showSettings = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.title)
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 20)
                
                VStack(spacing: 20) {
                    Button(action: {
                        // 清除聊天记录功能（占位）
                    }) {
                        Text("清除之前的聊天记录")
                            .font(.title)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Button(action: {
                        tempToken = mimoToken
                        showTokenAlert = true
                    }) {
                        Text("输入mimo的token")
                            .font(.title)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(Color.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .alert("设置token", isPresented: $showTokenAlert) {
                TextField("请输入token", text: $tempToken)
                Button("取消", role: .cancel) { }
                Button("确定") {
                    mimoToken = tempToken
                }
            } message: {
                Text("请输入您的mimo token")
            }
        }
    }
}

struct ChatHistoryView: View {
    @Binding var showChatHistory: Bool
    @Binding var chatRecords: [ChatRecord]
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    showChatHistory = false
                }
            
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Text("聊天列表")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.top, 16)
                    
                    Divider()
                        .background(Color.black)
                    
                    ForEach(chatRecords) { record in
                        Button(action: {
                            showChatHistory = false
                        }) {
                            Text(record.title)
                                .font(.title)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 12)
                        }
                        Divider()
                            .background(Color.black)
                    }
                    
                    Text("目前仅展示前四个对话记录")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 16)
                }
                .border(Color.black, width: 1)
                .background(Color.white)
            }
            .padding(.horizontal, 20)
            .padding(.top, 80)
            .frame(maxWidth: .infinity, alignment: .trailing)
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
