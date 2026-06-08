import UIKit
import Speech
import AVFoundation // 引入语音合成框架

class SiriViewController: UIViewController {
    
    private let backgroundView = UIView()
    private let container = UIView()
    private let titleLabel = UILabel()
    private let userTextLabel = UILabel()
    private let aiTextView = UITextView()
    private let voiceButton = UIButton(type: .system)
    
    private var isListening = false
    private var isLoading = false
    private var isFirstInteraction = true
    private var currentConversationId: String?
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    
    // 语音合成器
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    private var currentTranscript: String = ""
    
    private let tokenKey = "mimoCookieToken"
    private let conversationIdKey = "mimoConversationId"
    
    private var mimoToken: String {
        (UserDefaults.standard.string(forKey: tokenKey) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadConversationId()
        setupUI()
        setupSpeechRecognizer()
        requestPermissions()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopListening()
        // 退出界面时停止朗读
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    private func loadConversationId() {
        if let savedId = UserDefaults.standard.string(forKey: conversationIdKey) {
            currentConversationId = savedId
        }
    }
    
    private func saveConversationId(_ id: String) {
        currentConversationId = id
        UserDefaults.standard.set(id, forKey: conversationIdKey)
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#888888")
        
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = UIColor(hex: "#888888")
        view.addSubview(backgroundView)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        backgroundView.addGestureRecognizer(tapGesture)
        
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor(hex: "#e0e0e0")
        container.layer.cornerRadius = 30
        container.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        container.clipsToBounds = true
        view.addSubview(container)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "有什么需要帮助的？"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 48)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.lineSpacing = 1.2
        container.addSubview(titleLabel)
        
        userTextLabel.translatesAutoresizingMaskIntoConstraints = false
        userTextLabel.font = UIFont.systemFont(ofSize: 16)
        userTextLabel.textColor = .black
        userTextLabel.textAlignment = .left
        userTextLabel.numberOfLines = 0
        container.addSubview(userTextLabel)
        
        aiTextView.translatesAutoresizingMaskIntoConstraints = false
        aiTextView.font = UIFont.systemFont(ofSize: 24)
        aiTextView.textColor = .black
        aiTextView.textAlignment = .left
        aiTextView.isEditable = false
        aiTextView.isSelectable = true
        aiTextView.isScrollEnabled = true
        aiTextView.backgroundColor = .clear
        aiTextView.textContainerInset = .zero
        aiTextView.textContainer.lineFragmentPadding = 0
        container.addSubview(aiTextView)
        
        voiceButton.translatesAutoresizingMaskIntoConstraints = false
        voiceButton.setTitle("点击输入语音", for: .normal)
        voiceButton.titleLabel?.font = UIFont.systemFont(ofSize: 32)
        voiceButton.setTitleColor(.black, for: .normal)
        voiceButton.backgroundColor = UIColor(hex: "#e0e0e0")
        voiceButton.layer.cornerRadius = 20
        voiceButton.layer.borderWidth = 2
        voiceButton.layer.borderColor = UIColor(hex: "#666666").cgColor
        voiceButton.addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
        container.addSubview(voiceButton)
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            container.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.55),
            
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -40),
            titleLabel.heightAnchor.constraint(equalTo: container.heightAnchor, multiplier: 0.2),
            
            userTextLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            userTextLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            userTextLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 30),
            
            aiTextView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            aiTextView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            aiTextView.topAnchor.constraint(equalTo: userTextLabel.bottomAnchor, constant: 15),
            aiTextView.bottomAnchor.constraint(equalTo: voiceButton.topAnchor, constant: -20),
            
            voiceButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            voiceButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            voiceButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -40),
            voiceButton.heightAnchor.constraint(equalTo: container.heightAnchor, multiplier: 0.12)
        ])
        
        userTextLabel.isHidden = true
        aiTextView.isHidden = true
    }
    
    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        audioEngine = AVAudioEngine()
    }
    
    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized: print("语音识别权限已授权")
                case .denied: print("语音识别权限被拒绝")
                case .restricted: print("语音识别功能受限")
                case .notDetermined: print("语音识别权限未确定")
                @unknown default: break
                }
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    print("麦克风权限已授权")
                } else {
                    print("麦克风权限被拒绝")
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
        
        // 用户开始说话时，如果AI正在朗读，立刻打断（Siri核心交互逻辑）
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
        stopListening()
        currentTranscript = ""
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
        } catch {
            print("启动音频引擎失败: \(error)")
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            guard let result = result else { return }
            
            self.currentTranscript = result.bestTranscription.formattedString
            
            if result.isFinal {
                self.handleRecognitionResult(self.currentTranscript)
            }
            
            if error != nil || result.isFinal {
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
    }
    
    @objc private func handleTapAction() {
        if isFirstInteraction {
            if isListening {
                stopListening()
                handleRecognitionResult(currentTranscript)
                
                isFirstInteraction = false
                voiceButton.removeTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
                let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressAction))
                voiceButton.addGestureRecognizer(longPressGesture)
                voiceButton.setTitle("长按输入语音", for: .normal)
            } else {
                startListening()
                voiceButton.setTitle("点击停止", for: .normal)
            }
        }
    }
    
    @objc private func handleLongPressAction(_ gesture: UILongPressGestureRecognizer) {
        if !isFirstInteraction {
            if gesture.state == .began {
                startListening()
                voiceButton.setTitle("松开发送", for: .normal)
            } else if gesture.state == .ended {
                stopListening()
                handleRecognitionResult(currentTranscript)
                voiceButton.setTitle("长按输入语音", for: .normal)
            }
        }
    }
    
    private func handleRecognitionResult(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespaces)
        
        if trimmedText.isEmpty {
            updateVoiceButtonTitle()
        } else {
            transitionToResponseState(userText: trimmedText)
            sendToMimo(trimmedText)
        }
    }
    
    private func updateVoiceButtonTitle() {
        if isLoading {
            voiceButton.setTitle("AI回复中...", for: .normal)
        } else {
            voiceButton.setTitle(isFirstInteraction ? "点击输入语音" : "长按输入语音", for: .normal)
        }
    }
    
    private func transitionToResponseState(userText: String) {
        titleLabel.isHidden = true
        
        userTextLabel.text = userText
        aiTextView.text = ""
        userTextLabel.isHidden = false
        aiTextView.isHidden = false
    }
    
    private func appendMessage(_ text: String, isUser: Bool) {
        if text.isEmpty { return }
        
        if isUser {
            userTextLabel.text = text
        } else {
            aiTextView.text = (aiTextView.text ?? "") + text
            
            if !aiTextView.text.isEmpty {
                let range = NSMakeRange(aiTextView.text.count - 1, 1)
                aiTextView.scrollRangeToVisible(range)
            }
        }
    }
    
    // MARK: - 语音朗读功能
    private func speakText(_ text: String) {
        guard !text.isEmpty else { return }
        
        // 如果正在朗读，先停止
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        // 设置为中文女声 (zh-CN 默认就是女声)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        // 语速：默认语速稍微慢一点点更像Siri，可按需微调 (0.0 - 1.0)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
        
        // 朗读前需要激活音频会话，否则可能和录音冲突导致没声音
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("音频会话设置失败: \(error)")
        }
        
        speechSynthesizer.speak(utterance)
    }
    
    // MARK: - 网络请求
    private func sendToMimo(_ text: String) {
        guard !mimoToken.isEmpty else {
            appendMessage("请先在设置中配置 Token", isUser: false)
            return
        }
        
        isLoading = true
        updateVoiceButtonTitle()
        
        let token = mimoToken
        
        let sendChat = { (convId: String) in
            NetworkManager.shared.sendChatMessage(
                token: token,
                message: text,
                conversationId: convId,
                onMessage: { content in
                    self.appendMessage(content, isUser: false)
                },
                onFinish: {
                    self.isLoading = false
                    self.updateVoiceButtonTitle()
                    // 网络请求结束，开始朗读完整的回复内容
                    if let responseText = self.aiTextView.text {
                        self.speakText(responseText)
                    }
                },
                onError: { error in
                    self.isLoading = false
                    self.aiTextView.text = "网络错误: \(error.localizedDescription)"
                    self.updateVoiceButtonTitle()
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
                    self.saveConversationId(convId)
                    sendChat(convId)
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.aiTextView.text = "创建对话失败：\(error.localizedDescription)"
                        self.updateVoiceButtonTitle()
                    }
                }
            }
        }
    }
    
    @objc private func handleBackgroundTap() {
        dismiss(animated: true)
    }
}

// UIColor 扩展，支持十六进制颜色
extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

// UILabel 扩展，支持行间距
extension UILabel {
    var lineSpacing: CGFloat {
        get {
            return 0
        }
        set {
            guard let text = self.text, let font = self.font else { return }
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = newValue
            let attributedString = NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: font, NSAttributedString.Key.paragraphStyle: paragraphStyle])
            self.attributedText = attributedString
        }
    }
}
