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
        container.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner] // 只有上边有圆角
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
        voiceButton.setTitle("长按输入语音", for: .normal)
        voiceButton.titleLabel?.font = UIFont.systemFont(ofSize: 32)
        voiceButton.setTitleColor(.black, for: .normal)
        voiceButton.backgroundColor = UIColor(hex: "#e0e0e0")
        voiceButton.layer.cornerRadius = 20
        voiceButton.layer.borderWidth = 2
        voiceButton.layer.borderColor = UIColor(hex: "#666666").cgColor
        voiceButton.addTarget(self, action: #selector(handleLongPress), for: .touchUpInside)
        container.addSubview(voiceButton)
        
        // 添加长按手势
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        voiceButton.addGestureRecognizer(longPressGesture)
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // 容器位置：x: 0.05, y: 0.5, width: 0.9, height: 0.45
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: view.bounds.width * 0.05),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -view.bounds.width * 0.05),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            container.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.45),
            
            // 标题标签位置：x: 0.05, y: 0.35, width: 0.9, height: 0.2
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: container.bounds.width * 0.05),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -container.bounds.width * 0.05),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -container.bounds.height * 0.15),
            titleLabel.heightAnchor.constraint(equalTo: container.heightAnchor, multiplier: 0.2),
            
            // 用户回复文本标签位置：x: 0.05, y: 0.05, width: 0.9, height: 0.08
            userTextLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: container.bounds.width * 0.05),
            userTextLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -container.bounds.width * 0.05),
            userTextLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: container.bounds.height * 0.05),
            userTextLabel.heightAnchor.constraint(equalTo: container.heightAnchor, multiplier: 0.08),
            
            // AI回复文本块位置：x: 0.05, y: 0.15, width: 0.9, height: 0.65
            aiTextBlock.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: container.bounds.width * 0.05),
            aiTextBlock.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -container.bounds.width * 0.05),
            aiTextBlock.topAnchor.constraint(equalTo: container.topAnchor, constant: container.bounds.height * 0.15),
            aiTextBlock.heightAnchor.constraint(equalTo: container.heightAnchor, multiplier: 0.65),
            
            // 按钮位置：x: 0.05, y: 0.85, width: 0.9, height: 0.12
            voiceButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: container.bounds.width * 0.05),
            voiceButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -container.bounds.width * 0.05),
            voiceButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -container.bounds.height * 0.08),
            voiceButton.heightAnchor.constraint(equalTo: container.heightAnchor, multiplier: 0.12)
        ])
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
                    self.startListening()
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
            voiceButton.setTitle("停止", for: .normal)
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
        voiceButton.setTitle("长按输入语音", for: .normal)
    }
    
    private func handleRecognitionResult(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespaces)
        
        if trimmedText.isEmpty {
            showChatInterface(isEmptyResult: true)
        } else {
            showChatInterface(isEmptyResult: false, userText: trimmedText, aiText: "你好，我可以：\n看电视\n搜索新闻\n运行代码\n哦~")
        }
    }
    
    private func showChatInterface(isEmptyResult: Bool = false, userText: String = "", aiText: String = "") {
        if isEmptyResult {
            titleLabel.text = "未听清，请输入"
            userTextLabel.text = ""
            aiTextBlock.text = ""
        } else {
            titleLabel.text = "有什么需要帮助的？"
            userTextLabel.text = userText
            aiTextBlock.text = aiText
        }
        
        voiceButton.isHidden = false
        userTextLabel.isHidden = isEmptyResult
        aiTextBlock.isHidden = isEmptyResult
    }
    
    private func addMessage(_ text: String, isUser: Bool) {
        if isUser {
            userTextLabel.text = text
        } else {
            aiTextBlock.text = text
        }
    }
    
    private func sendToMimo(_ text: String) {
        guard !mimoToken.isEmpty else {
            addMessage("请先在设置中配置 Token", isUser: false)
            return
        }
        
        isLoading = true
        addMessage("AI正在处理...", isUser: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.addMessage("你好，我可以：\n看电视\n搜索新闻\n运行代码\n哦~", isUser: false)
            self.isLoading = false
        }
    }
    
    @objc private func handleBackgroundTap() {
        dismiss(animated: true)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            startListening()
        } else if gesture.state == .ended {
            stopListening()
        }
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
            guard let text = self.text, let font = self.font else { return 0 }
            let attributedString = NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: font])
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = self.lineSpacing
            let attributedStringWithLineSpacing = NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: font, NSAttributedString.Key.paragraphStyle: paragraphStyle])
            return paragraphStyle.lineSpacing
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
