import UIKit
import Speech

class SiriViewController: UIViewController {
    
    private let backgroundView = UIView()
    private let container = UIView()
    private let titleLabel = UILabel()
    private let userTextLabel = UILabel()
    private let aiTextBlock = UILabel()
    private let voiceButton = UIButton(type: .system)
    
    private var messages: [Message] = []
    private var isListening = false
    private var isLoading = false
    private var currentConversationId: String?
    private var isFirstInteraction = true
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    
    // 用于保存实时识别到的文本
    private var currentTranscript: String = ""
    
    private let tokenKey = "mimoCookieToken"
    private let conversationIdKey = "mimoConversationId"
    
    private var mimoToken: String {
        UserDefaults.standard.string(forKey: tokenKey) ?? ""
    }
    
    // 约束引用
    private var containerLeadingInitial: NSLayoutConstraint!
    private var containerTrailingInitial: NSLayoutConstraint!
    private var containerBottomInitial: NSLayoutConstraint!
    private var containerHeightInitial: NSLayoutConstraint!
    
    private var containerLeadingResponse: NSLayoutConstraint!
    private var containerTrailingResponse: NSLayoutConstraint!
    private var containerCenterYResponse: NSLayoutConstraint!
    private var containerHeightResponse: NSLayoutConstraint!
    
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
        // 设置背景颜色为 #888888
        view.backgroundColor = UIColor(hex: "#888888")
        
        // 背景视图（用于点击关闭）
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = UIColor(hex: "#888888")
        view.addSubview(backgroundView)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        backgroundView.addGestureRecognizer(tapGesture)
        
        // 容器 - 底部弹出的圆角矩形
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor(hex: "#e0e0e0")
        container.layer.cornerRadius = 30
        container.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        container.clipsToBounds = true
        view.addSubview(container)
        
        // 标题标签 - "有什么需要帮助的？"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "有什么需要帮助的？"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 48)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.lineSpacing = 1.2
        container.addSubview(titleLabel)
        
        // 用户回复文本标签
        userTextLabel.translatesAutoresizingMaskIntoConstraints = false
        userTextLabel.font = UIFont.systemFont(ofSize: 16)
        userTextLabel.textColor = .black
        userTextLabel.textAlignment = .left
        userTextLabel.numberOfLines = 0
        container.addSubview(userTextLabel)
        
        // AI回复文本块
        aiTextBlock.translatesAutoresizingMaskIntoConstraints = false
        aiTextBlock.font = UIFont.systemFont(ofSize: 24)
        aiTextBlock.textColor = .black
        aiTextBlock.textAlignment = .left
        aiTextBlock.numberOfLines = 0
        aiTextBlock.lineBreakMode = .byWordWrapping
        aiTextBlock.lineSpacing = 1.5
        container.addSubview(aiTextBlock)
        
        // 长按输入语音按钮
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
        
        // 初始状态约束
        containerLeadingInitial = container.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        containerTrailingInitial = container.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        containerBottomInitial = container.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        containerHeightInitial = container.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.55)
        
        // 回复状态约束
        containerLeadingResponse = container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: view.bounds.width * 0.05)
        containerTrailingResponse = container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -view.bounds.width * 0.05)
        containerCenterYResponse = container.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        containerHeightResponse = container.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.45)
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            containerLeadingInitial,
            containerTrailingInitial,
            containerBottomInitial,
            containerHeightInitial,
            
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -40),
            titleLabel.heightAnchor.constraint(equalTo: container.heightAnchor, multiplier: 0.2),
            
            userTextLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            userTextLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            userTextLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            userTextLabel.heightAnchor.constraint(equalTo: container.heightAnchor, multiplier: 0.08),
            
            aiTextBlock.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            aiTextBlock.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            aiTextBlock.topAnchor.constraint(equalTo: container.topAnchor, constant: 60),
            aiTextBlock.heightAnchor.constraint(equalTo: container.heightAnchor, multiplier: 0.65),
            
            voiceButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            voiceButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            voiceButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -40),
            voiceButton.heightAnchor.constraint(equalTo: container.heightAnchor, multiplier: 0.12)
        ])
        
        // 初始状态下隐藏用户输入和AI回复
        userTextLabel.isHidden = true
        aiTextBlock.isHidden = true
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
            if isFirstInteraction {
                voiceButton.setTitle("点击输入语音", for: .normal)
            } else {
                voiceButton.setTitle("长按输入语音", for: .normal)
            }
        } else {
            transitionToResponseState(userText: trimmedText)
            sendToMimo(trimmedText)
        }
    }
    
    private func transitionToResponseState(userText: String) {
        titleLabel.text = ""
        
        userTextLabel.text = userText
        aiTextBlock.text = "AI正在处理..."
        
        userTextLabel.isHidden = false
        aiTextBlock.isHidden = false
        
        NSLayoutConstraint.deactivate([
            containerLeadingInitial,
            containerTrailingInitial,
            containerBottomInitial,
            containerHeightInitial
        ])
        
        NSLayoutConstraint.activate([
            containerLeadingResponse,
            containerTrailingResponse,
            containerCenterYResponse,
            containerHeightResponse
        ])
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func addMessage(_ text: String, isUser: Bool) {
        if isUser {
            userTextLabel.text = text
        } else {
            aiTextBlock.text = text
        }
    }
    
    // MARK: - 真实网络请求
    private func sendToMimo(_ text: String) {
        guard !mimoToken.isEmpty else {
            addMessage("请先在设置中配置 Token", isUser: false)
            return
        }
        
        isLoading = true
        
        // 替换为您真实的 Mimo API 地址
        guard let url = URL(string: "https://api.mimu.chat/v1/chat/completions") else {
            addMessage("API 地址配置错误", isUser: false)
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(mimoToken)", forHTTPHeaderField: "Authorization")
        
        // 构建请求参数，根据 Mimo 实际要求调整
        let body: [String: Any] = [
            "model": "mimo", // 视实际情况修改
            "messages": [["role": "user", "content": text]],
            "stream": false
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            addMessage("请求构建失败", isUser: false)
            isLoading = false
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.addMessage("网络错误: \(error.localizedDescription)", isUser: false)
                    return
                }
                
                guard let data = data else {
                    self.addMessage("未收到数据", isUser: false)
                    return
                }
                
                // 解析返回的 JSON 数据，提取 AI 的回复
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        
                        // 更新到 UI 上
                        self.addMessage(content, isUser: false)
                        
                        // 如果 API 返回了 conversationId，可以将其保存下来以便下次传入
                        if let convId = json["id"] as? String {
                            self.currentConversationId = convId
                            UserDefaults.standard.set(convId, forKey: self.conversationIdKey)
                        }
                        
                    } else {
                        self.addMessage("解析响应失败", isUser: false)
                    }
                } catch {
                    self.addMessage("JSON 解析错误", isUser: false)
                }
            }
        }
        
        task.resume()
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
