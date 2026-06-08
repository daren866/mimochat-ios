import SwiftUI

// MARK: - 数据模型

struct TokenUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    let nativeUsage: NativeUsage
}

struct NativeUsage: Codable {
    let completion_tokens: Int
    let prompt_tokens: Int
    let total_tokens: Int
    let prompt_tokens_details: PromptTokensDetails
    let completion_tokens_details: CompletionTokensDetails
}

struct PromptTokensDetails: Codable {
    let cached_tokens: Int
}

struct CompletionTokensDetails: Codable {
    let reasoning_tokens: Int
}

struct Message: Identifiable {
    let id = UUID()
    var text: String
    let isUser: Bool
    let timestamp: Date
    var tokenUsage: TokenUsage?

    init(text: String, isUser: Bool) {
        self.text = text
        self.isUser = isUser
        self.timestamp = Date()
    }
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
        case title, conversationId, createTime, updateTime
        case creator, updater, deleteFlag, type
    }

    init(title: String, conversationId: String, createTime: String, updateTime: String,
         creator: String, updater: String, deleteFlag: Int, type: String) {
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

struct DialogItem: Codable {
    let conversationId: String
    let msgId: String
    let inputInfo: InputInfo
    let createTime: String
    let updateTime: String
    let dialogLogDetailList: [DialogLogDetail]
}

struct InputInfo: Codable {
    let query: String
    let multiMedias: [String]
}

struct DialogLogDetail: Codable {
    let id: Int
    let result: String
    let dialogStatus: String
    let model: String
}

struct DialogListResponse: Codable {
    let code: Int
    let msg: String
    let data: [DialogItem]
}

struct SendMessageResponse: Codable {
    let code: Int
    let msg: String
    let data: SendMessageData?
}

struct SendMessageData: Codable {
    let content: String?
    let conversationId: String?
    let messageId: String?
}

struct ConversationSaveResponse: Codable {
    let code: Int
    let msg: String
    let data: ConversationData
}

struct ConversationData: Codable {
    let id: Int
    let creator: String
    let createTime: String
    let updater: String
    let updateTime: String
    let title: String
    let conversationId: String
    let deleteFlag: Int
    let type: String
}

struct ModelConfig: Codable {
    let enableThinking: Bool
    let webSearchStatus: String
    let model: String
    let temperature: Double
    let topP: Double
}

struct ChatRequestBody: Codable {
    let msgId: String
    let conversationId: String
    let query: String
    let isEditedQuery: Bool
    let modelConfig: ModelConfig
    let multiMedias: [String]
}

struct ApiResponse: Codable {
    let code: Int
    let msg: String
    let data: String?
}

// MARK: - 网络管理器

class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    private let baseURL = "https://aistudio.xiaomimimo.com/open-apis"
    private let ph = "ELjE%2FJoWhAXG%2ByRH0Qx%2BDw%3D%3D"

    private func baseRequest(path: String, token: String) -> URLRequest {
        let urlString = "\(baseURL)/\(path)?xiaomichatbot_ph=\(ph)"
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("*/*", forHTTPHeaderField: "accept")
        request.setValue("system", forHTTPHeaderField: "accept-language")
        request.setValue("no-cache", forHTTPHeaderField: "cache-control")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("no-cache", forHTTPHeaderField: "pragma")
        request.setValue("u=1, i", forHTTPHeaderField: "priority")
        request.setValue("Etc/GMT-8", forHTTPHeaderField: "x-timezone")
        request.setValue(token, forHTTPHeaderField: "cookie")
        request.setValue("https://aistudio.xiaomimimo.com/", forHTTPHeaderField: "Referer")
        return request
    }

    // MARK: - 获取聊天列表
    func fetchChatRecords(token: String, completion: @escaping (Result<[ChatRecord], Error>) -> Void) {
        var request = baseRequest(path: "chat/conversation/list", token: token)
        let body: [String: Any] = [
            "pageInfo": ["pageNum": 1, "pageSize": 20]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "NetworkManager", code: -1,
                                               userInfo: [NSLocalizedDescriptionKey: "无数据返回"])))
                }
                return
            }
            do {
                let resp = try JSONDecoder().decode(ChatListResponse.self, from: data)
                if resp.code == 0 {
                    DispatchQueue.main.async { completion(.success(resp.data.dataList)) }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "API", code: resp.code,
                                                   userInfo: [NSLocalizedDescriptionKey: resp.msg])))
                    }
                }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }
    
    // MARK: - 获取对话详情
    func fetchDialogList(token: String, conversationId: String, completion: @escaping (Result<[DialogItem], Error>) -> Void) {
        var request = baseRequest(path: "chat/dialog/list", token: token)
        let body: [String: Any] = [
            "queryParam": ["conversationId": conversationId],
            "pageInfo": ["pageNum": 1, "pageSize": 10]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "NetworkManager", code: -1,
                                               userInfo: [NSLocalizedDescriptionKey: "无数据返回"])))
                }
                return
            }
            do {
                let resp = try JSONDecoder().decode(DialogListResponse.self, from: data)
                if resp.code == 0 {
                    DispatchQueue.main.async { completion(.success(resp.data)) }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "API", code: resp.code,
                                                   userInfo: [NSLocalizedDescriptionKey: resp.msg])))
                    }
                }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }

    // MARK: - 创建对话
    func createConversation(token: String, conversationId: String, completion: @escaping (Result<String, Error>) -> Void) {
        var request = baseRequest(path: "chat/conversation/save", token: token)
        let body: [String: Any] = [
            "conversationId": conversationId,
            "title": "新对话",
            "type": "chat"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "NetworkManager", code: -1,
                                               userInfo: [NSLocalizedDescriptionKey: "无数据返回"])))
                }
                return
            }
            do {
                let resp = try JSONDecoder().decode(ConversationSaveResponse.self, from: data)
                if resp.code == 0 {
                    DispatchQueue.main.async { completion(.success(resp.data.conversationId)) }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "API", code: resp.code,
                                                   userInfo: [NSLocalizedDescriptionKey: resp.msg])))
                    }
                }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }

    // MARK: - 发送消息 (SSE流式响应)
    func sendChatMessage(token: String, message: String, conversationId: String,
                         onMessage: @escaping (String) -> Void,
                         onFinish: @escaping () -> Void,
                         onError: @escaping (Error) -> Void,
                         onUsage: ((TokenUsage) -> Void)? = nil) {
        let urlString = "\(baseURL)/bot/chat?xiaomichatbot_ph=\(ph)"
        guard let url = URL(string: urlString) else {
            onError(NSError(domain: "NetworkManager", code: -1,
                           userInfo: [NSLocalizedDescriptionKey: "无效的URL"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("*/*", forHTTPHeaderField: "accept")
        request.setValue("system", forHTTPHeaderField: "accept-language")
        request.setValue("no-cache", forHTTPHeaderField: "cache-control")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("no-cache", forHTTPHeaderField: "pragma")
        request.setValue("u=1, i", forHTTPHeaderField: "priority")
        request.setValue("Etc/GMT-8", forHTTPHeaderField: "x-timezone")
        request.setValue(token, forHTTPHeaderField: "cookie")
        request.setValue("https://aistudio.xiaomimimo.com/", forHTTPHeaderField: "Referer")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 120

        let modelConfig = ModelConfig(
            enableThinking: false,
            webSearchStatus: "disabled",
            model: "mimo-v2.5",
            temperature: 0.8,
            topP: 0.95
        )

        let chatBody = ChatRequestBody(
            msgId: UUID().uuidString,
            conversationId: conversationId,
            query: message,
            isEditedQuery: false,
            modelConfig: modelConfig,
            multiMedias: []
        )

        do {
            request.httpBody = try JSONEncoder().encode(chatBody)
        } catch {
            onError(error)
            return
        }

        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: SSESessionDelegate(onMessage: onMessage, onFinish: onFinish, onError: onError, onUsage: onUsage), delegateQueue: nil)
        let task = session.dataTask(with: request)
        task.resume()
    }
    
    // MARK: - 删除聊天记录
    func deleteConversations(token: String, conversationIds: [String], completion: @escaping (Result<Void, Error>) -> Void) {
        var request = baseRequest(path: "chat/conversation/delete", token: token)
        request.httpBody = try? JSONSerialization.data(withJSONObject: conversationIds)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "NetworkManager", code: -1,
                                               userInfo: [NSLocalizedDescriptionKey: "无数据返回"])))
                }
                return
            }
            do {
                let resp = try JSONDecoder().decode(ApiResponse.self, from: data)
                if resp.code == 0 {
                    DispatchQueue.main.async { completion(.success(())) }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "API", code: resp.code,
                                                   userInfo: [NSLocalizedDescriptionKey: resp.msg])))
                    }
                }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }

    private func extractContent(from data: String) -> String? {
        guard let jsonData = data.data(using: .utf8) else { return nil }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let type = json["type"] as? String,
               type == "text",
               let content = json["content"] as? String {
                return filterContent(content)
            }
        } catch {
            print("Failed to parse SSE data: \(error)")
        }
        return nil
    }
    
    private func filterContent(_ content: String) -> String {
        if content == "<think>" {
            return ""
        }
        if content.hasPrefix("<think>") {
            if let endIndex = content.range(of: "</think>")?.upperBound {
                return String(content[endIndex...])
            }
            return ""
        }
        if content.contains("</think>") {
            if let closeIndex = content.range(of: "</think>")?.upperBound {
                return String(content[closeIndex...])
            }
        }
        return content
    }
}

class SSESessionDelegate: NSObject, URLSessionDataDelegate {
    private let onMessage: (String) -> Void
    private let onFinish: () -> Void
    private let onError: (Error) -> Void
    private let onUsage: ((TokenUsage) -> Void)?
    private var rawDataBuffer = Data()
    private var eventBuffer = ""
    private var currentEvent = ""
    
    init(onMessage: @escaping (String) -> Void, onFinish: @escaping () -> Void, onError: @escaping (Error) -> Void, onUsage: ((TokenUsage) -> Void)? = nil) {
        self.onMessage = onMessage
        self.onFinish = onFinish
        self.onError = onError
        self.onUsage = onUsage
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        rawDataBuffer.append(data)
        processRawDataBuffer()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        session.finishTasksAndInvalidate()
        if let error = error {
            DispatchQueue.main.async { self.onError(error) }
        } else {
            processRawDataBuffer()
            DispatchQueue.main.async { self.onFinish() }
        }
    }
    
    private func processRawDataBuffer() {
        while let newlineRange = rawDataBuffer.range(of: Data([0x0A])) {
            let lineData = rawDataBuffer[..<newlineRange.lowerBound]
            rawDataBuffer = rawDataBuffer[newlineRange.upperBound...]
            
            if let line = String(data: lineData, encoding: .utf8) {
                processLine(line)
            }
        }
    }
    
    private func processLine(_ line: String) {
        if line.hasPrefix("event:") {
            currentEvent = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
        } else if line.hasPrefix("data:") {
            let dataContent = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            
            if currentEvent == "message" {
                if let content = parseAndExtractContent(from: dataContent) {
                    DispatchQueue.main.async { self.onMessage(content) }
                }
            } else if currentEvent == "usage" {
                parseUsageData(dataContent)
            } else if currentEvent == "finish" {
                DispatchQueue.main.async { self.onFinish() }
            }
        }
    }
    
    private func parseUsageData(_ dataString: String) {
        guard !dataString.isEmpty, let jsonData = dataString.data(using: .utf8), let usage = try? JSONDecoder().decode(TokenUsage.self, from: jsonData) else {
            print("Failed to parse usage data")
            return
        }
        DispatchQueue.main.async {
            self.onUsage?(usage)
        }
    }
    
    private func parseAndExtractContent(from dataString: String) -> String? {
        guard !dataString.isEmpty, let jsonData = dataString.data(using: .utf8) else { return nil }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let type = json["type"] as? String,
               type == "text",
               let content = json["content"] as? String {
                return filterContent(content)
            }
        } catch {
            print("JSON parse failed: \(error), data: \(dataString.prefix(100))")
        }
        return nil
    }
    
    private func filterContent(_ content: String) -> String {
        // 过滤控制字符
        let filtered = content.filter { char in
            let scalars = char.unicodeScalars
            for scalar in scalars {
                if scalar.isASCII && scalar.value < 32 && scalar.value != 9 && scalar.value != 10 && scalar.value != 13 {
                    return false
                }
            }
            return true
        }
        
        // 过滤 thinking 标签
        if filtered == "<think>" {
            return ""
        }
        if filtered.hasPrefix("<think>") {
            if let endIndex = filtered.range(of: "</think>")?.upperBound {
                return String(filtered[endIndex...])
            }
            return ""
        }
        if filtered.contains("</think>") {
            if let closeIndex = filtered.range(of: "</think>")?.upperBound {
                return String(filtered[closeIndex...])
            }
        }
        return filtered
    }
}

// MARK: - ContentView

struct ContentView: View {
    @State private var inputText = ""
    @State private var messages: [Message] = []
    @State private var showChat = false
    @State private var showSettings = false
    @State private var showChatHistory = false
    @State private var showSiriMode = false
    @State private var mimoToken = ""
    @State private var chatRecords: [ChatRecord] = []
    @State private var isLoading = false
    @State private var currentConversationId: String?
    @State private var errorMessage: String?
    private let tokenKey = "mimoCookieToken"
    private let conversationIdKey = "mimoConversationId"
    
    init() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("OpenSiriMode"),
            object: nil,
            queue: .main
        ) { _ in
            self.showSiriMode = true
        }
    }

    var body: some View {
        Group {
            if showSiriMode {
                SiriModeView(
                    mimoToken: $mimoToken,
                    onClose: { showSiriMode = false },
                    onSend: sendMessage
                )
            } else if showChat {
                ChatView(
                    messages: $messages,
                    inputText: $inputText,
                    showSettings: $showSettings,
                    showChatHistory: $showChatHistory,
                    mimoToken: $mimoToken,
                    chatRecords: $chatRecords,
                    isLoading: $isLoading,
                    currentConversationId: $currentConversationId,
                    loadChatRecords: loadChatRecords,
                    saveToken: saveToken,
                    selectChatRecord: selectChatRecord,
                    appendText: appendText,
                    saveConversationId: saveConversationId,
                    deleteAllChatRecords: deleteAllChatRecords
                )
            } else {
                WelcomeView(
                    inputText: $inputText,
                    onSend: sendMessage,
                    showSettings: $showSettings,
                    showChatHistory: $showChatHistory,
                    mimoToken: $mimoToken,
                    chatRecords: $chatRecords,
                    isLoading: $isLoading,
                    errorMessage: $errorMessage,
                    loadChatRecords: loadChatRecords,
                    saveToken: saveToken,
                    selectChatRecord: selectChatRecord,
                    deleteAllChatRecords: deleteAllChatRecords
                )
            }
        }
        .onAppear {
            loadToken()
        }
    }

    private func saveToken(_ token: String) {
        mimoToken = token
        UserDefaults.standard.set(token, forKey: tokenKey)
    }

    private func loadToken() {
        if let savedToken = UserDefaults.standard.string(forKey: tokenKey) {
            mimoToken = savedToken
        }
        if let savedConversationId = UserDefaults.standard.string(forKey: conversationIdKey) {
            currentConversationId = savedConversationId
        }
    }
    
    private func saveConversationId(_ id: String) {
        currentConversationId = id
        UserDefaults.standard.set(id, forKey: conversationIdKey)
    }
    
    private func appendText(_ text: String, at index: Int) {
        DispatchQueue.main.async {
            if index < self.messages.count {
                self.messages[index].text.append(text)
            }
        }
    }
    
    private func selectChatRecord(_ conversationId: String) {
        guard !mimoToken.isEmpty else { return }
        
        NetworkManager.shared.fetchDialogList(token: mimoToken, conversationId: conversationId) { result in
            switch result {
            case .success(let dialogs):
                DispatchQueue.main.async {
                    self.messages.removeAll()
                    
                    for dialog in dialogs {
                        self.messages.append(Message(text: dialog.inputInfo.query, isUser: true))
                        
                        if let detail = dialog.dialogLogDetailList.first {
                            let content = self.filterResultContent(detail.result)
                            self.messages.append(Message(text: content, isUser: false))
                        }
                    }
                    
                    self.saveConversationId(conversationId)
                    self.showChat = true
                }
            case .failure(let error):
                print("获取对话详情失败: \(error)")
            }
        }
    }
    
    private func filterResultContent(_ content: String) -> String {
        if let startIndex = content.range(of: "</think>")?.upperBound {
            return String(content[startIndex...])
        }
        return content
    }

    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        guard !mimoToken.isEmpty else {
            errorMessage = "请先在设置中配置 Token"
            showSettings = true
            return
        }

        messages.append(Message(text: trimmed, isUser: true))
        showChat = true
        inputText = ""
        isLoading = true
        errorMessage = nil

        let token = mimoToken
        
        messages.append(Message(text: "", isUser: false))
        let messageIndex = messages.count - 1
        
        let sendChat = { (convId: String) in
            NetworkManager.shared.sendChatMessage(
                token: token,
                message: trimmed,
                conversationId: convId,
                onMessage: { content in
                    self.appendText(content, at: messageIndex)
                },
                onFinish: {
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                },
                onError: { error in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        if messageIndex < self.messages.count {
                            self.messages[messageIndex].text = "请求失败：\(error.localizedDescription)"
                        }
                    }
                },
                onUsage: { usage in
                    DispatchQueue.main.async {
                        if messageIndex < self.messages.count {
                            self.messages[messageIndex].tokenUsage = usage
                        }
                    }
                }
            )
        }

        if let convId = currentConversationId {
            sendChat(convId)
        } else {
            let newConversationId = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
            NetworkManager.shared.createConversation(
                token: token,
                conversationId: newConversationId
            ) { result in
                switch result {
                case .success(let convId):
                    DispatchQueue.main.async {
                        saveConversationId(convId)
                        sendChat(convId)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.messages.append(Message(text: "创建对话失败：\(error.localizedDescription)", isUser: false))
                    }
                }
            }
        }
    }

    private func loadChatRecords() {
        guard !mimoToken.isEmpty else { return }
        isLoading = true

        NetworkManager.shared.fetchChatRecords(token: mimoToken) { result in
            isLoading = false
            switch result {
            case .success(let records):
                chatRecords = Array(records.prefix(4))
            case .failure(let error):
                print("加载聊天记录失败: \(error)")
            }
        }
    }
    
    private func deleteAllChatRecords() {
        guard !mimoToken.isEmpty else { return }
        
        let conversationIds = chatRecords.map { $0.conversationId }
        guard !conversationIds.isEmpty else {
            chatRecords.removeAll()
            currentConversationId = nil
            UserDefaults.standard.removeObject(forKey: conversationIdKey)
            return
        }
        
        isLoading = true
        NetworkManager.shared.deleteConversations(token: mimoToken, conversationIds: conversationIds) { result in
            isLoading = false
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self.chatRecords.removeAll()
                    self.currentConversationId = nil
                    UserDefaults.standard.removeObject(forKey: self.conversationIdKey)
                }
            case .failure(let error):
                print("删除聊天记录失败: \(error)")
            }
        }
    }
}

// MARK: - WelcomeView

struct WelcomeView: View {
    @Binding var inputText: String
    let onSend: () -> Void
    @Binding var showSettings: Bool
    @Binding var showChatHistory: Bool
    @Binding var mimoToken: String
    @Binding var chatRecords: [ChatRecord]
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?
    let loadChatRecords: () -> Void
    let saveToken: (String) -> Void
    let selectChatRecord: (String) -> Void
    let deleteAllChatRecords: () -> Void

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

                    Button(action: { showChatHistory = true }) {
                        Image(systemName: "doc.text")
                            .font(.title)
                            .foregroundColor(.black)
                    }

                    Button(action: { showSettings = true }) {
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

                if let error = errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                }

                HStack(spacing: 0) {
                    TextField("请输入文本", text: $inputText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(0)
                        .disabled(isLoading)

                    Button(action: {
                        onSend()
                    }) {
                        if isLoading {
                            ProgressView()
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                        } else {
                            Text("发送")
                                .font(.title2)
                                .foregroundColor(.black)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(0)
                        }
                    }
                    .disabled(isLoading)
                }
                .border(Color.black, width: 1)
                .padding(.horizontal, 20)
            }

            if showSettings {
                SettingsView(
                    showSettings: $showSettings,
                    mimoToken: mimoToken,
                    saveToken: saveToken,
                    deleteAllChatRecords: deleteAllChatRecords
                )
            }

            if showChatHistory {
                ChatHistoryView(
                    showChatHistory: $showChatHistory,
                    chatRecords: $chatRecords,
                    loadChatRecords: loadChatRecords,
                    onSelectChat: selectChatRecord
                )
            }
        }
    }
}

// MARK: - ChatView

struct ChatView: View {
    @Binding var messages: [Message]
    @Binding var inputText: String
    @Binding var showSettings: Bool
    @Binding var showChatHistory: Bool
    @Binding var mimoToken: String
    @Binding var chatRecords: [ChatRecord]
    @Binding var isLoading: Bool
    @Binding var currentConversationId: String?
    let loadChatRecords: () -> Void
    let saveToken: (String) -> Void
    let selectChatRecord: (String) -> Void
    let appendText: (String, Int) -> Void
    let saveConversationId: (String) -> Void
    let deleteAllChatRecords: () -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Text("MiMo2.5-Pro")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.black)

                    Spacer()

                    Button(action: { showChatHistory = true }) {
                        Image(systemName: "doc.text")
                            .font(.title)
                            .foregroundColor(.black)
                    }

                    Button(action: { showSettings = true }) {
                        Image(systemName: "gear")
                            .font(.title)
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 20)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }

                            if isLoading {
                                HStack {
                                    TypingIndicator()
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .id("loading")
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .onChange(of: messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo(messages.last?.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: isLoading) { _ in
                        withAnimation {
                            proxy.scrollTo("loading", anchor: .bottom)
                        }
                    }
                }

                HStack(spacing: 0) {
                    TextField("请输入文本", text: $inputText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(0)
                        .disabled(isLoading)
                        .onSubmit {
                            sendMessage()
                        }

                    Button(action: sendMessage) {
                        if isLoading {
                            ProgressView()
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                        } else {
                            Text("发送")
                                .font(.title2)
                                .foregroundColor(.black)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(0)
                        }
                    }
                    .disabled(isLoading)
                }
                .border(Color.black, width: 1)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(Color.white)

            if showSettings {
                SettingsView(
                    showSettings: $showSettings,
                    mimoToken: mimoToken,
                    saveToken: saveToken,
                    deleteAllChatRecords: deleteAllChatRecords
                )
            }

            if showChatHistory {
                ChatHistoryView(
                    showChatHistory: $showChatHistory,
                    chatRecords: $chatRecords,
                    loadChatRecords: loadChatRecords,
                    onSelectChat: selectChatRecord
                )
            }
        }
    }

    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isLoading else { return }

        guard !mimoToken.isEmpty else {
            messages.append(Message(text: "请先在设置中配置 Token", isUser: false))
            return
        }

        messages.append(Message(text: trimmed, isUser: true))
        inputText = ""
        isLoading = true

        let token = mimoToken
        
        messages.append(Message(text: "", isUser: false))
        let messageIndex = messages.count - 1
        
        let sendChat = { (convId: String) in
            NetworkManager.shared.sendChatMessage(
                token: token,
                message: trimmed,
                conversationId: convId,
                onMessage: { content in
                    appendText(content, messageIndex)
                },
                onFinish: {
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                },
                onError: { error in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        if messageIndex < self.messages.count {
                            self.messages[messageIndex].text = "请求失败：\(error.localizedDescription)"
                        }
                    }
                },
                onUsage: { usage in
                    DispatchQueue.main.async {
                        if messageIndex < self.messages.count {
                            self.messages[messageIndex].tokenUsage = usage
                        }
                    }
                }
            )
        }

        if let convId = currentConversationId {
            sendChat(convId)
        } else {
            let newConversationId = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
            NetworkManager.shared.createConversation(
                token: token,
                conversationId: newConversationId
            ) { result in
                switch result {
                case .success(let convId):
                    DispatchQueue.main.async {
                        saveConversationId(convId)
                        sendChat(convId)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.messages.append(Message(text: "创建对话失败：\(error.localizedDescription)", isUser: false))
                    }
                }
            }
        }
    }
}

// MARK: - TypingIndicator

struct TypingIndicator: View {
    @State private var phase = 0.0

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .offset(y: phase == Double(index) ? -6 : 0)
                    .animation(
                        .easeInOut(duration: 0.4)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                        value: phase
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
        .onAppear {
            phase = 1.0
        }
    }
}

// MARK: - SettingsView

struct SettingsView: View {
    @Binding var showSettings: Bool
    let mimoToken: String
    let saveToken: (String) -> Void
    let deleteAllChatRecords: () -> Void
    @State private var showTokenView = false
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture { showSettings = false }

            VStack(spacing: 0) {
                HStack {
                    Text("设置")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)

                    Spacer()

                    Button(action: { showSettings = false }) {
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
                        showDeleteConfirm = true
                    }) {
                        Text("清除之前的聊天记录")
                            .font(.title)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button(action: { showTokenView = true }) {
                        HStack {
                            Text("输入mimo的token")
                                .font(.title)
                                .foregroundColor(.black)
                            Spacer()
                            if mimoToken.isEmpty {
                                Text("未配置")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            } else {
                                Text("已配置")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
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
                    mimoToken: mimoToken,
                    saveToken: saveToken
                )
            }
            
            if showDeleteConfirm {
                DeleteConfirmView(
                    showDeleteConfirm: $showDeleteConfirm,
                    onConfirm: {
                        deleteAllChatRecords()
                        showSettings = false
                    }
                )
            }
        }
    }
}

// MARK: - DeleteConfirmView

struct DeleteConfirmView: View {
    @Binding var showDeleteConfirm: Bool
    let onConfirm: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture { showDeleteConfirm = false }
            
            VStack(spacing: 20) {
                Text("是否删除所有聊天记录?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 20) {
                    Button(action: {
                        showDeleteConfirm = false
                    }) {
                        Text("取消")
                            .font(.title3)
                            .foregroundColor(.black)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        onConfirm()
                    }) {
                        Text("确定")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(30)
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - TokenSettingView

struct TokenSettingView: View {
    @Binding var showTokenView: Bool
    let mimoToken: String
    let saveToken: (String) -> Void
    @State private var inputText = ""
    @State private var saved = false

    var body: some View {
        ZStack {
            Color.white
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                HStack {
                    Button(action: { showTokenView = false }) {
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
                        saveToken(inputText)
                        saved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            showTokenView = false
                        }
                    }) {
                        Text("保存")
                            .font(.title)
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 20)

                VStack(alignment: .leading, spacing: 8) {
                    Text("请输入从浏览器获取的 Cookie")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    TextEditor(text: $inputText)
                        .font(.body)
                        .frame(minHeight: 120)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.black, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 20)

                if saved {
                    Text("保存成功!")
                        .foregroundColor(.green)
                        .font(.headline)
                        .padding(.top, 12)
                }

                Spacer()
            }
        }
        .onAppear {
            inputText = mimoToken
        }
    }
}

// MARK: - ChatHistoryView

struct ChatHistoryView: View {
    @Binding var showChatHistory: Bool
    @Binding var chatRecords: [ChatRecord]
    let loadChatRecords: () -> Void
    let onSelectChat: (String) -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture { showChatHistory = false }

            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    HStack {
                        Text("聊天列表")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Spacer()
                        Button(action: { showChatHistory = false }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                    Divider()
                        .background(Color.black)

                    if chatRecords.isEmpty {
                        VStack(spacing: 8) {
                            Spacer()
                            Text("暂无聊天记录")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("请先配置 Token")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 200)
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(chatRecords) { record in
                                    Button(action: {
                                        showChatHistory = false
                                        onSelectChat(record.conversationId)
                                    }) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(record.title)
                                                .font(.headline)
                                                .foregroundColor(.black)
                                                .lineLimit(2)
                                            Text(record.updateTime)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                    }
                                    Divider()
                                        .background(Color.gray.opacity(0.3))
                                }
                            }
                        }
                    }

                    Text("目前仅展示前4个对话记录")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.vertical, 8)
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

// MARK: - MessageBubble

struct MessageBubble: View {
    let message: Message
    @State private var showActionSheet = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 50)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.black)
                        .cornerRadius(16)
                }
                .contextMenu {
                    Button("复制") {
                        UIPasteboard.general.string = message.text
                    }
                    if message.tokenUsage != nil {
                        Button("消耗token") {
                            showActionSheet = true
                        }
                    }
                }

                Spacer(minLength: 50)
            }
        }
        .sheet(isPresented: $showActionSheet) {
            TokenUsageDetailView(usage: message.tokenUsage!)
        }
    }
}

// MARK: - TokenUsageDetailView

struct TokenUsageDetailView: View {
    let usage: TokenUsage

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Token 使用详情")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 20)

                    VStack(spacing: 16) {
                        TokenInfoRow(title: "提示词 Token", value: "\(usage.promptTokens)")
                        TokenInfoRow(title: "响应 Token", value: "\(usage.completionTokens)")
                        TokenInfoRow(title: "总 Token", value: "\(usage.totalTokens)")

                        Divider()

                        Text("Native Usage")
                            .font(.title)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)

                        TokenInfoRow(title: "提示词 Tokens", value: "\(usage.nativeUsage.prompt_tokens)")
                        TokenInfoRow(title: "响应 Tokens", value: "\(usage.nativeUsage.completion_tokens)")
                        TokenInfoRow(title: "总 Tokens", value: "\(usage.nativeUsage.total_tokens)")

                        Divider()

                        Text("详细信息")
                            .font(.title)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)

                        TokenInfoRow(title: "缓存 Tokens", value: "\(usage.nativeUsage.prompt_tokens_details.cached_tokens)")
                        TokenInfoRow(title: "推理 Tokens", value: "\(usage.nativeUsage.completion_tokens_details.reasoning_tokens)")
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    @Environment(\.presentationMode) private var presentationMode
}

struct TokenInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundColor(.black)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

// MARK: - SiriModeView

struct SiriModeView: View {
    @Binding var mimoToken: String
    let onClose: () -> Void
    let onSend: () -> Void
    @State private var isListening = false
    @State private var recognizedText = ""
    @State private var showKeyboard = false
    @State private var messages: [Message] = []
    @State private var isLoading = false
    @State private var currentConversationId: String?
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    if !isLoading {
                        onClose()
                    }
                }
            
            VStack {
                if messages.isEmpty {
                    VStack {
                        Spacer()
                        
                        VStack(spacing: 12) {
                            Text("有什么问题，请说")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            
                            Text(isListening ? "正在听..." : "语音听写已开启")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(40)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(24)
                        .padding(.horizontal, 30)
                        
                        Spacer()
                    }
                } else {
                    VStack(spacing: 0) {
                        Text("Mimo siri")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.top, 20)
                            .padding(.horizontal, 20)
                        
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(messages) { message in
                                    MessageBubble(message: message)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                        }
                        .frame(maxHeight: 300)
                        
                        HStack(spacing: 10) {
                            Button(action: {
                                showKeyboard.toggle()
                            }) {
                                Image(systemName: "textformat")
                                    .font(.title)
                                    .foregroundColor(.black)
                            }
                            
                            if showKeyboard {
                                HStack {
                                    TextField("输入文本", text: $recognizedText)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color.white)
                                        .cornerRadius(8)
                                    
                                    Button(action: sendMessage) {
                                        Text("发送")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 12)
                                            .background(Color.blue)
                                            .cornerRadius(8)
                                    }
                                    .disabled(isLoading)
                                }
                            } else {
                                Button(action: toggleListening) {
                                    Text(isListening ? "停止" : "按我说话")
                                        .font(.title)
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 40)
                                        .padding(.vertical, 16)
                                        .background(Color.white)
                                        .cornerRadius(30)
                                        .border(Color.black, width: 2)
                                }
                                .disabled(isLoading)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 20)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(24)
                    .padding(.horizontal, 20)
                    .padding(.top, 100)
                }
            }
        }
        .onAppear {
            startListening()
        }
    }
    
    private func startListening() {
        isListening = true
    }
    
    private func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }
    
    private func stopListening() {
        isListening = false
    }
    
    private func sendMessage() {
        guard !recognizedText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        messages.append(Message(text: recognizedText, isUser: true))
        let trimmedText = recognizedText
        recognizedText = ""
        isLoading = true
        
        messages.append(Message(text: "", isUser: false))
        let messageIndex = messages.count - 1
        
        let token = mimoToken
        let sendChat = { (convId: String) in
            NetworkManager.shared.sendChatMessage(
                token: token,
                message: trimmedText,
                conversationId: convId,
                onMessage: { content in
                    DispatchQueue.main.async {
                        if messageIndex < self.messages.count {
                            self.messages[messageIndex].text.append(content)
                        }
                    }
                },
                onFinish: {
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                },
                onError: { error in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        if messageIndex < self.messages.count {
                            self.messages[messageIndex].text = "请求失败：\(error.localizedDescription)"
                        }
                    }
                }
            )
        }
        
        if let convId = currentConversationId {
            sendChat(convId)
        } else {
            let newConversationId = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
            NetworkManager.shared.createConversation(
                token: token,
                conversationId: newConversationId
            ) { result in
                switch result {
                case .success(let convId):
                    DispatchQueue.main.async {
                        self.currentConversationId = convId
                        sendChat(convId)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.messages.append(Message(text: "创建对话失败：\(error.localizedDescription)", isUser: false))
                    }
                }
            }
        }
    }
}


