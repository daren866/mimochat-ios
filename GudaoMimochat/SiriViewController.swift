import UIKit
import Speech

class SiriViewController: UIViewController {
    
    private let backgroundView = UIView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let settingsButton = UIButton(type: .system)
    
    private let chatContainerView = UIView()
    private let messagesScrollView = UIScrollView()
    private let messagesStackView = UIStackView()
    
    private let inputContainerView = UIView()
    private let keyboardButton = UIButton(type: .system)
    private let inputTextField = UITextField()
    private let sendButton = UIButton(type: .system)
    
    private let speakButton = UIButton(type: .system)
    
    private var messages: [Message] = []
    private var isListening = false
    private var isLoading = false
    private var currentConversationId: String?
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    
    private let tokenKey = "mimoCookieToken"
    private let conversationIdKey = "mimoConversationId"
    
    private var mimoToken: String {
        UserDefaults.standard.string(forKey: tokenKey) ?? ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSpeechRecognizer()
        requestPermissions()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopListening()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(white: 0.6, alpha: 1.0)
        
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = UIColor(white: 0.6, alpha: 1.0)
        view.addSubview(backgroundView)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        backgroundView.addGestureRecognizer(tapGesture)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        contentView.layer.cornerRadius = 24
        contentView.clipsToBounds = true
        view.addSubview(contentView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "有什么问题，请说"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)
        
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.setImage(UIImage(systemName: "gear"), for: .normal)
        settingsButton.tintColor = .black
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        contentView.addSubview(settingsButton)
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "语音听写已开启"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textColor = .gray
        subtitleLabel.textAlignment = .center
        contentView.addSubview(subtitleLabel)
        
        speakButton.translatesAutoresizingMaskIntoConstraints = false
        speakButton.setTitle("按我说话", for: .normal)
        speakButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        speakButton.setTitleColor(.black, for: .normal)
        speakButton.backgroundColor = .white
        speakButton.layer.cornerRadius = 30
        speakButton.layer.borderWidth = 2
        speakButton.layer.borderColor = UIColor.black.cgColor
        speakButton.addTarget(self, action: #selector(toggleListening), for: .touchUpInside)
        contentView.addSubview(speakButton)
        
        chatContainerView.translatesAutoresizingMaskIntoConstraints = false
        chatContainerView.isHidden = true
        contentView.addSubview(chatContainerView)
        
        messagesScrollView.translatesAutoresizingMaskIntoConstraints = false
        messagesScrollView.showsVerticalScrollIndicator = false
        chatContainerView.addSubview(messagesScrollView)
        
        messagesStackView.translatesAutoresizingMaskIntoConstraints = false
        messagesStackView.axis = .vertical
        messagesStackView.spacing = 12
        messagesScrollView.addSubview(messagesStackView)
        
        inputContainerView.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.isHidden = true
        contentView.addSubview(inputContainerView)
        
        keyboardButton.translatesAutoresizingMaskIntoConstraints = false
        keyboardButton.setImage(UIImage(systemName: "keyboard"), for: .normal)
        keyboardButton.tintColor = .black
        keyboardButton.addTarget(self, action: #selector(toggleKeyboardMode), for: .touchUpInside)
        inputContainerView.addSubview(keyboardButton)
        
        inputTextField.translatesAutoresizingMaskIntoConstraints = false
        inputTextField.placeholder = "输入文本"
        inputTextField.borderStyle = .roundedRect
        inputTextField.addTarget(self, action: #selector(textFieldDidReturn), for: .editingDidEndOnExit)
        inputContainerView.addSubview(inputTextField)
        
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setTitle("发送", for: .normal)
        sendButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.backgroundColor = .blue
        sendButton.layer.cornerRadius = 8
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        inputContainerView.addSubview(sendButton)
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            settingsButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            settingsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            settingsButton.widthAnchor.constraint(equalToConstant: 44),
            settingsButton.heightAnchor.constraint(equalToConstant: 44),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            subtitleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            speakButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            speakButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            speakButton.widthAnchor.constraint(equalToConstant: 200),
            speakButton.heightAnchor.constraint(equalToConstant: 60),
            speakButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
            
            // 默认界面的键盘切换按钮，位于左下角
            keyboardButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            keyboardButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -50),
            keyboardButton.widthAnchor.constraint(equalToConstant: 36),
            keyboardButton.heightAnchor.constraint(equalToConstant: 36),
            
            chatContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            chatContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            chatContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            messagesScrollView.topAnchor.constraint(equalTo: chatContainerView.topAnchor),
            messagesScrollView.leadingAnchor.constraint(equalTo: chatContainerView.leadingAnchor),
            messagesScrollView.trailingAnchor.constraint(equalTo: chatContainerView.trailingAnchor),
            messagesScrollView.bottomAnchor.constraint(equalTo: chatContainerView.bottomAnchor),
            messagesScrollView.heightAnchor.constraint(equalToConstant: 300),
            
            messagesStackView.topAnchor.constraint(equalTo: messagesScrollView.topAnchor),
            messagesStackView.leadingAnchor.constraint(equalTo: messagesScrollView.leadingAnchor),
            messagesStackView.trailingAnchor.constraint(equalTo: messagesScrollView.trailingAnchor),
            messagesStackView.widthAnchor.constraint(equalTo: messagesScrollView.widthAnchor),
            
            inputContainerView.topAnchor.constraint(equalTo: chatContainerView.bottomAnchor, constant: 10),
            inputContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            inputContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            inputContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            inputContainerView.heightAnchor.constraint(equalToConstant: 50),
            
            // 聊天界面的键盘切换按钮布局
            keyboardButton.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            keyboardButton.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            keyboardButton.widthAnchor.constraint(equalToConstant: 44),
            
            inputTextField.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            inputTextField.leadingAnchor.constraint(equalTo: keyboardButton.trailingAnchor, constant: 10),
            inputTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10),
            inputTextField.heightAnchor.constraint(equalToConstant: 36),
            
            sendButton.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 60),
            sendButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        audioEngine = AVAudioEngine()
    }
    
    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized: print("语音识别权限已授权")
                case .denied: self?.subtitleLabel.text = "语音识别权限被拒绝"
                case .restricted: self?.subtitleLabel.text = "语音识别功能受限"
                case .notDetermined: self?.subtitleLabel.text = "语音识别权限未确定"
                @unknown default: break
                }
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    print("麦克风权限已授权")
                    // 授权成功后自动开始听写（对应图3默认状态）
                    self?.startListening()
                } else {
                    self?.subtitleLabel.text = "麦克风权限被拒绝"
                }
            }
        }
    }
    
    private func startListening() {
        guard let audioEngine = audioEngine, let speechRecognizer = speechRecognizer else { return }
        
        if !speechRecognizer.isAvailable {
            print("语音识别不可用")
            return
        }
        
        stopListening()
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isListening = true
            subtitleLabel.text = "正在听..."
            speakButton.setTitle("停止", for: .normal)
        } catch {
            print("启动音频引擎失败: \(error)")
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let transcript = result.bestTranscription.formattedString
                if result.isFinal {
                    self.handleRecognitionResult(transcript)
                }
            }
            
            // 如果发生错误或者识别结束，则停止听写
            if error != nil || (result?.isFinal ?? false) {
                self.stopListening()
            }
        }
    }
    
    private func stopListening() {
        recognitionTask?.cancel()
        recognitionTask = nil
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest = nil
        isListening = false
        subtitleLabel.text = "语音听写已开启"
        speakButton.setTitle("按我说话", for: .normal)
    }
    
    private func handleRecognitionResult(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespaces)
        
        if trimmedText.isEmpty {
            // 未识别到有效语音，切换到图1（键盘输入模式）
            showChatInterface(isEmptyResult: true)
        } else {
            // 识别到有效语音，正常展示并请求接口
            showChatInterface(isEmptyResult: false)
            addMessage(trimmedText, isUser: true)
            sendToMimo(trimmedText)
        }
    }
    
    // 根据是否识别到内容切换不同UI状态
    private func showChatInterface(isEmptyResult: Bool = false) {
        if isEmptyResult {
            titleLabel.text = "未听清，请输入"
        } else {
            titleLabel.text = "Mimo siri"
        }
        
        subtitleLabel.isHidden = true
        speakButton.isHidden = true
        chatContainerView.isHidden = false
        inputContainerView.isHidden = false
        
        // 自动弹出键盘
        inputTextField.becomeFirstResponder()
    }
    
    private func addMessage(_ text: String, isUser: Bool) {
        let messageLabel = UILabel()
        messageLabel.text = text
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        messageLabel.numberOfLines = 0
        messageLabel.lineBreakMode = .byWordWrapping
        
        let messageView = UIView()
        messageView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageView.addSubview(messageLabel)
        
        if isUser {
            messageLabel.textColor = .white
            messageView.backgroundColor = .blue
            messageView.layer.cornerRadius = 16
            NSLayoutConstraint.activate([
                messageLabel.topAnchor.constraint(equalTo: messageView.topAnchor, constant: 12),
                messageLabel.leadingAnchor.constraint(equalTo: messageView.leadingAnchor, constant: 16),
                messageLabel.trailingAnchor.constraint(equalTo: messageView.trailingAnchor, constant: -16),
                messageLabel.bottomAnchor.constraint(equalTo: messageView.bottomAnchor, constant: -12),
                messageLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 250)
            ])
            
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(messageView)
            NSLayoutConstraint.activate([
                messageView.topAnchor.constraint(equalTo: container.topAnchor),
                messageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                container.heightAnchor.constraint(equalTo: messageView.heightAnchor)
            ])
            messagesStackView.addArrangedSubview(container)
        } else {
            messageLabel.textColor = .black
            messageView.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
            messageView.layer.cornerRadius = 16
            NSLayoutConstraint.activate([
                messageLabel.topAnchor.constraint(equalTo: messageView.topAnchor, constant: 12),
                messageLabel.leadingAnchor.constraint(equalTo: messageView.leadingAnchor, constant: 16),
                messageLabel.trailingAnchor.constraint(equalTo: messageView.trailingAnchor, constant: -16),
                messageLabel.bottomAnchor.constraint(equalTo: messageView.bottomAnchor, constant: -12),
                messageLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 250)
            ])
            
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(messageView)
            NSLayoutConstraint.activate([
                messageView.topAnchor.constraint(equalTo: container.topAnchor),
                messageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                container.heightAnchor.constraint(equalTo: messageView.heightAnchor)
            ])
            messagesStackView.addArrangedSubview(container)
        }
        
        messages.append(Message(text: text, isUser: isUser))
        
        DispatchQueue.main.async {
            self.messagesScrollView.layoutIfNeeded()
            let bottomOffset = CGPoint(x: 0, y: self.messagesStackView.frame.height - self.messagesScrollView.bounds.height)
            self.messagesScrollView.setContentOffset(bottomOffset, animated: true)
        }
    }
    
    private func sendToMimo(_ text: String) {
        guard !mimoToken.isEmpty else {
            addMessage("请先在设置中配置 Token", isUser: false)
            return
        }
        
        isLoading = true
        messages.append(Message(text: "", isUser: false))
        
        let loadingLabel = UILabel()
        loadingLabel.text = "..."
        loadingLabel.font = UIFont.systemFont(ofSize: 16)
        loadingLabel.textColor = .gray
        
        let loadingView = UIView()
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        loadingView.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        loadingView.layer.cornerRadius = 16
        loadingView.addSubview(loadingLabel)
        
        NSLayoutConstraint.activate([
            loadingLabel.topAnchor.constraint(equalTo: loadingView.topAnchor, constant: 12),
            loadingLabel.leadingAnchor.constraint(equalTo: loadingView.leadingAnchor, constant: 16),
            loadingLabel.trailingAnchor.constraint(equalTo: loadingView.trailingAnchor, constant: -16),
            loadingLabel.bottomAnchor.constraint(equalTo: loadingView.bottomAnchor, constant: -12)
        ])
        
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(loadingView)
        container.tag = 999
        
        NSLayoutConstraint.activate([
            loadingView.topAnchor.constraint(equalTo: container.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            container.heightAnchor.constraint(equalTo: loadingView.heightAnchor)
        ])
        
        messagesStackView.addArrangedSubview(container)
        
        DispatchQueue.main.async {
            self.messagesScrollView.layoutIfNeeded()
            let bottomOffset = CGPoint(x: 0, y: self.messagesStackView.frame.height - self.messagesScrollView.bounds.height)
            self.messagesScrollView.setContentOffset(bottomOffset, animated: true)
        }
        
        let sendChat = { [weak self] (convId: String) in
            guard let self = self else { return }
            NetworkManager.shared.sendChatMessage(
                token: self.mimoToken,
                message: text,
                conversationId: convId,
                onMessage: { content in
                    DispatchQueue.main.async {
                        if let loadingContainer = self.messagesStackView.viewWithTag(999) {
                            loadingContainer.removeFromSuperview()
                        }
                        if self.messages.count > 0 {
                            self.messages[self.messages.count - 1].text.append(content)
                            self.updateLastMessage(content)
                        }
                    }
                },
                onFinish: {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        if let loadingContainer = self.messagesStackView.viewWithTag(999) {
                            loadingContainer.removeFromSuperview()
                        }
                    }
                },
                onError: { error in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        if let loadingContainer = self.messagesStackView.viewWithTag(999) {
                            loadingContainer.removeFromSuperview()
                        }
                        self.addMessage("请求失败：\(error.localizedDescription)", isUser: false)
                    }
                }
            )
        }
        
        if let convId = currentConversationId {
            sendChat(convId)
        } else {
            let newConversationId = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
            NetworkManager.shared.createConversation(
                token: mimoToken,
                conversationId: newConversationId
            ) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let convId):
                    DispatchQueue.main.async {
                        self.currentConversationId = convId
                        sendChat(convId)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.isLoading = false
                        if let loadingContainer = self.messagesStackView.viewWithTag(999) {
                            loadingContainer.removeFromSuperview()
                        }
                        self.addMessage("创建对话失败：\(error.localizedDescription)", isUser: false)
                    }
                }
            }
        }
    }
    
    private func updateLastMessage(_ content: String) {
        if let lastArrangedSubview = messagesStackView.arrangedSubviews.last,
           let messageView = lastArrangedSubview.subviews.first,
           let messageLabel = messageView.subviews.first as? UILabel {
            messageLabel.text = messages.last?.text
        }
        
        DispatchQueue.main.async {
            self.messagesScrollView.layoutIfNeeded()
            let bottomOffset = CGPoint(x: 0, y: self.messagesStackView.frame.height - self.messagesScrollView.bounds.height)
            self.messagesScrollView.setContentOffset(bottomOffset, animated: true)
        }
    }
    
    @objc private func handleBackgroundTap() {
        dismiss(animated: true)
    }
    
    @objc private func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }
    
    @objc private func toggleKeyboardMode() {
        // 点击左下角键盘图标，主动切换到输入法模式
        showChatInterface(isEmptyResult: false)
    }
    
    @objc private func textFieldDidReturn() {
        sendMessage()
    }
    
    @objc private func sendMessage() {
        guard let text = inputTextField.text, !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        inputTextField.text = ""
        addMessage(text, isUser: true)
        sendToMimo(text)
    }
    
    @objc private func openSettings() {
        dismiss(animated: true)
    }
}

extension SiriViewController {
    struct Message {
        var text: String
        let isUser: Bool
    }
}
