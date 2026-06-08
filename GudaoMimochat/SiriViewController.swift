import UIKit
import Speech

class SiriViewController: UIViewController {
    
    private let backgroundView = UIView()
    private let bubbleContainer = UIView()
    private let titleLabel = UILabel()
    private let messageBlock = UILabel()
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
        
        // 气泡容器
        bubbleContainer.translatesAutoresizingMaskIntoConstraints = false
        bubbleContainer.backgroundColor = UIColor(hex: "#e0e0e0")
        bubbleContainer.layer.cornerRadius = 20
        bubbleContainer.clipsToBounds = true
        view.addSubview(bubbleContainer)
        
        // 标题标签 - "你好！"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "你好！"
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .left
        bubbleContainer.addSubview(titleLabel)
        
        // 消息文本块
        messageBlock.translatesAutoresizingMaskIntoConstraints = false
        messageBlock.text = "我是AI助手哦\n我在这是AI恢复，支持多行。AI可以查天气，搜索网络信息，助手\n我在这是AI恢复，支持多行。AI可以查天气，搜索网络信息，助手\n我在"
        messageBlock.font = UIFont.systemFont(ofSize: 20)
        messageBlock.textColor = .black
        messageBlock.textAlignment = .left
        messageBlock.numberOfLines = 0
        messageBlock.lineBreakMode = .byWordWrapping
        bubbleContainer.addSubview(messageBlock)
        
        // 长按输入语音按钮
        voiceButton.translatesAutoresizingMaskIntoConstraints = false
        voiceButton.setTitle("长按输入语音", for: .normal)
        voiceButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        voiceButton.setTitleColor(.black, for: .normal)
        voiceButton.backgroundColor = UIColor(hex: "#e0e0e0")
        voiceButton.layer.cornerRadius = 15
        voiceButton.layer.borderWidth = 2
        voiceButton.layer.borderColor = UIColor(hex: "#666666").cgColor
        voiceButton.addTarget(self, action: #selector(handleLongPress), for: .touchUpInside)
        bubbleContainer.addSubview(voiceButton)
        
        // 添加长按手势
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        voiceButton.addGestureRecognizer(longPressGesture)
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // 气泡容器位置：x: 0.05, y: 0.5, width: 0.9, height: 0.45
            bubbleContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: view.bounds.width * 0.05),
            bubbleContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -view.bounds.width * 0.05),
            bubbleContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            bubbleContainer.heightAnchor.constraint(equalTo: view.bounds.height * 0.45),
            
            // 标题标签位置：x: 0, y: 0, width: 1, height: 0.1
            titleLabel.topAnchor.constraint(equalTo: bubbleContainer.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: bubbleContainer.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: bubbleContainer.trailingAnchor, constant: -20),
            titleLabel.heightAnchor.constraint(equalTo: bubbleContainer.heightAnchor, multiplier: 0.1),
            
            // 消息文本块位置：x: 0, y: 0.12, width: 1, height: 0.68
            messageBlock.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            messageBlock.leadingAnchor.constraint(equalTo: bubbleContainer.leadingAnchor, constant: 20),
            messageBlock.trailingAnchor.constraint(equalTo: bubbleContainer.trailingAnchor, constant: -20),
            messageBlock.heightAnchor.constraint(equalTo: bubbleContainer.heightAnchor, multiplier: 0.68),
            
            // 按钮位置：x: 0.05, y: 0.85, width: 0.9, height: 0.15
            voiceButton.leadingAnchor.constraint(equalTo: bubbleContainer.leadingAnchor, constant: bubbleContainer.bounds.width * 0.05),
            voiceButton.trailingAnchor.constraint(equalTo: bubbleContainer.trailingAnchor, constant: -bubbleContainer.bounds.width * 0.05),
            voiceButton.bottomAnchor.constraint(equalTo: bubbleContainer.bottomAnchor, constant: -bubbleContainer.bounds.height * 0.15),
            voiceButton.heightAnchor.constraint(equalTo: bubbleContainer.heightAnchor, multiplier: 0.15)
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
            
            if error != nil || (result.isFinal ?? false) {
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
            showChatInterface(isEmptyResult: false)
            addMessage(trimmedText, isUser: true)
            sendToMimo(trimmedText)
        }
    }
    
    private func showChatInterface(isEmptyResult: Bool = false) {
        if isEmptyResult {
            messageBlock.text = "未听清，请输入"
        } else {
            messageBlock.text = "我是AI助手哦\n我在这是AI恢复，支持多行。AI可以查天气，搜索网络信息，助手\n我在这是AI恢复，支持多行。AI可以查天气，搜索网络信息，助手\n我在"
        }
        
        voiceButton.isHidden = true
        titleLabel.isHidden = true
    }
    
    private func addMessage(_ text: String, isUser: Bool) {
        if isUser {
            messageBlock.text = text
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
            self.addMessage("这是AI的回复内容", isUser: false)
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
