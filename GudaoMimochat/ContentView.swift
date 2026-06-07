import SwiftUI

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct ChatRecord: Identifiable, Codable {
    let id: UUID
    let title: String
    let conversationId: String
    let createTime: String
    let updateTime: String
    let creator: String
    let updater: String
    let deleteFlag: Int
    let type: String
    
    enum CodingKeys: String, CodingKey {
        case title
        case conversationId
        case createTime
        case updateTime
        case creator
        case updater
        case deleteFlag
        case type
    }
    
    init(title: String, conversationId: String, createTime: String, updateTime: String, creator: String, updater: String, deleteFlag: Int, type: String) {
        self.id = UUID()
        self.title = title
        self.conversationId = conversationId
        self.createTime = createTime
        self.updateTime = updateTime
        self.creator = creator
        self.updater = updater
        self.deleteFlag = deleteFlag
        self.type = type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        title = try container.decode(String.self, forKey: .title)
        conversationId = try container.decode(String.self, forKey: .conversationId)
        createTime = try container.decode(String.self, forKey: .createTime)
        updateTime = try container.decode(String.self, forKey: .updateTime)
        creator = try container.decode(String.self, forKey: .creator)
        updater = try container.decode(String.self, forKey: .updater)
        deleteFlag = try container.decode(Int.self, forKey: .deleteFlag)
        type = try container.decode(String.self, forKey: .type)
    }
}

struct ChatListResponse: Codable {
    let code: Int
    let msg: String
    let data: ChatListData
}

struct ChatListData: Codable {
    let total: Int
    let pageNum: Int
    let dataList: [ChatRecord]
}

struct PageInfo: Codable {
    let pageNum: Int
    let pageSize: Int
}

struct ContentView: View {
    @State private var inputText = ""
    @State private var messages: [Message] = []
    @State private var showChat = false
    @State private var showSettings = false
    @State private var showChatHistory = false
    @State private var mimoToken = ""
    @State private var chatRecords: [ChatRecord] = []
    @State private var isLoading = false
    
    var body: some View {
        if showChat {
            ChatView(
                messages: $messages,
                inputText: $inputText,
                showSettings: $showSettings,
                showChatHistory: $showChatHistory,
                mimoToken: $mimoToken,
                chatRecords: $chatRecords,
                loadChatRecords: loadChatRecords
            )
        } else {
            WelcomeView(
                inputText: $inputText,
                onSend: sendMessage,
                showSettings: $showSettings,
                showChatHistory: $showChatHistory,
                mimoToken: $mimoToken,
                chatRecords: $chatRecords,
                loadChatRecords: loadChatRecords
            )
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
    
    private func loadChatRecords() {
        guard !mimoToken.isEmpty else { return }
        
        isLoading = true
        
        let url = URL(string: "https://aistudio.xiaomimimo.com/open-apis/chat/conversation/list?xiaomichatbot_ph=ELjE%2FJoWhAXG%2ByRH0Qx%2BDw%3D%3D")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("*/*", forHTTPHeaderField: "accept")
        request.setValue("system", forHTTPHeaderField: "accept-language")
        request.setValue("no-cache", forHTTPHeaderField: "cache-control")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("no-cache", forHTTPHeaderField: "pragma")
        request.setValue("u=1, i", forHTTPHeaderField: "priority")
        request.setValue("Etc/GMT-8", forHTTPHeaderField: "x-timezone")
        request.setValue(mimoToken, forHTTPHeaderField: "cookie")
        request.setValue("https://aistudio.xiaomimimo.com/", forHTTPHeaderField: "Referer")
        
        let pageInfo = PageInfo(pageNum: 1, pageSize: 20)
        let body = ["pageInfo": pageInfo]
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        } catch {
            print("Failed to serialize request body: \(error)")
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    print("Request failed: \(error)")
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(ChatListResponse.self, from: data)
                    if response.code == 0 {
                        chatRecords = Array(response.data.dataList.prefix(4))
                    }
                } catch {
                    print("Failed to decode response: \(error)")
                    print("Response data: \(String(data: data, encoding: .utf8) ?? "N/A")")
                }
            }
        }.resume()
    }
}

struct WelcomeView: View {
    @Binding var inputText: String
    let onSend: () -> Void
    @Binding var showSettings: Bool
    @Binding var showChatHistory: Bool
    @Binding var mimoToken: String
    @Binding var chatRecords: [ChatRecord]
    let loadChatRecords: () -> Void
    
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
                    chatRecords: $chatRecords,
                    loadChatRecords: loadChatRecords
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
    let loadChatRecords: () -> Void
    
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
                    chatRecords: $chatRecords,
                    loadChatRecords: loadChatRecords
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
    @State private var showTokenView = false
    
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
                        showTokenView = true
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
            
            if showTokenView {
                TokenSettingView(
                    showTokenView: $showTokenView,
                    mimoToken: $mimoToken
                )
            }
        }
    }
}

struct TokenSettingView: View {
    @Binding var showTokenView: Bool
    @Binding var mimoToken: String
    @State private var inputText = ""
    
    var body: some View {
        ZStack {
            Color.white
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        showTokenView = false
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.title)
                            .foregroundColor(.black)
                    }
                    
                    Text("设置token")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Button(action: {
                        mimoToken = inputText
                        showTokenView = false
                    }) {
                        Text("保存")
                            .font(.title)
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 20)
                
                TextField("请输入cookie", text: $inputText)
                    .font(.title)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .border(Color.black, width: 1)
                    .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .onAppear {
            inputText = mimoToken
        }
    }
}

struct ChatHistoryView: View {
    @Binding var showChatHistory: Bool
    @Binding var chatRecords: [ChatRecord]
    let loadChatRecords: () -> Void
    
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
        .onAppear {
            loadChatRecords()
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
