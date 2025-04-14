import Foundation
import Combine

/// BFF服务协议
protocol BFFServiceProtocol {
    /// 发送消息到BFF服务
    /// - Parameters:
    ///   - message: 用户消息内容
    ///   - workspaceId: 工作区ID
    /// - Returns: 包含AI响应的Publisher
    func sendMessage(_ message: String, workspaceId: UUID) -> AnyPublisher<String, Error>
    
    /// 发送流式消息到BFF服务
    /// - Parameters:
    ///   - message: 用户消息内容
    ///   - workspaceId: 工作区ID
    ///   - onUpdate: 流式响应更新回调
    ///   - onComplete: 响应完成回调
    ///   - onError: 错误回调
    func sendStreamMessage(
        _ message: String,
        workspaceId: UUID,
        onUpdate: @escaping (String) -> Void,
        onComplete: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    )
    
    /// 取消当前进行的请求
    func cancelOngoingRequests()
}



/// API错误类型
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case serverError(String)
    case unknownError(Error)
    case noData
    case apiKeyMissing
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL地址"
        case .invalidResponse:
            return "无效的服务器响应"
        case .httpError(let code):
            return "HTTP错误: \(code)"
        case .decodingError:
            return "数据解码错误"
        case .serverError(let message):
            return "服务器错误: \(message)"
        case .unknownError(let error):
            return "未知错误: \(error.localizedDescription)"
        case .noData:
            return "服务器没有返回数据"
        case .apiKeyMissing:
            return "API密钥缺失，请在设置中配置API密钥"
        }
    }
}

/// OpenAI API ChatCompletion请求结构
struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Float?
    let stream: Bool?
    
    struct Message: Codable {
        let role: String
        let content: String
    }
}

/// OpenAI API ChatCompletion响应结构
struct ChatCompletionResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    
    struct Choice: Codable {
        let index: Int
        let message: Message
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case index
            case message
            case finishReason = "finish_reason"
        }
    }
    
    struct Message: Codable {
        let role: String
        let content: String
    }
}

/// 流式响应部分数据结构
struct ChatCompletionStreamResponse: Codable {
    let id: String?
    let object: String?
    let created: Int?
    let model: String?
    let choices: [Choice]?
    
    struct Choice: Codable {
        let index: Int?
        let delta: Delta?
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case index
            case delta
            case finishReason = "finish_reason"
        }
    }
    
    struct Delta: Codable {
        let role: String?
        let content: String?
    }
}

/// 真实的BFF服务实现
class RealBFFService: BFFServiceProtocol {
    static let shared = RealBFFService()
    
    private var cancellables = Set<AnyCancellable>()
    private var urlSession: URLSession
    private var streamTask: URLSessionDataTask?
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60.0
        urlSession = URLSession(configuration: config)
    }
    
    /// 发送消息到OpenAI API
    func sendMessage(_ message: String, workspaceId: UUID) -> AnyPublisher<String, Error> {
        return Future<String, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(APIError.unknownError(NSError(domain: "BFFService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service instance is nil"]))))
                return
            }
            
            // 获取设置
            let settings = SettingsManager.shared.loadSettings()
            
            // 检查API密钥
            guard !settings.apiKey.isEmpty else {
                promise(.failure(APIError.apiKeyMissing))
                return
            }
            
            // 创建URL
            guard let url = URL(string: "\(settings.apiEndpoint)/chat/completions") else {
                promise(.failure(APIError.invalidURL))
                return
            }
            
            // 创建请求
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(settings.apiKey)", forHTTPHeaderField: "Authorization")
            
            // 创建请求体
            let requestBody = ChatCompletionRequest(
                model: settings.selectedModel,
                messages: [
                    ChatCompletionRequest.Message(role: "system", content: "你是一个很了解h5页面实现的技术产品经理，和用户一起讨论h5页面产品需求，最终生成一份相对清晰的页面描述，最终你的回答会交给LLM进行页面生成"),
                    ChatCompletionRequest.Message(role: "user", content: message)
                ],
                temperature: 0.7,
                stream: false
            )
            
            // 编码请求体
            do {
                let encoder = JSONEncoder()
                request.httpBody = try encoder.encode(requestBody)
            } catch {
                promise(.failure(APIError.unknownError(error)))
                return
            }
            
            // 发送请求
            self.urlSession.dataTaskPublisher(for: request)
                .tryMap { data, response -> Data in
                    // 检查HTTP响应
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw APIError.invalidResponse
                    }
                    
                    // 检查状态码
                    guard (200..<300).contains(httpResponse.statusCode) else {
                        // 尝试解码错误消息
                        if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let errorObj = errorJson["error"] as? [String: Any],
                           let errorMessage = errorObj["message"] as? String {
                            throw APIError.serverError(errorMessage)
                        }
                        throw APIError.httpError(httpResponse.statusCode)
                    }
                    
                    return data
                }
                .decode(type: ChatCompletionResponse.self, decoder: JSONDecoder())
                .tryMap { response -> String in
                    // 获取响应文本
                    guard let firstChoice = response.choices.first else {
                        throw APIError.noData
                    }
                    return firstChoice.message.content
                }
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { content in
                        promise(.success(content))
                    }
                )
                .store(in: &self.cancellables)
        }
        .eraseToAnyPublisher()
    }
    
    /// 发送流式消息到OpenAI API
    func sendStreamMessage(
        _ message: String, 
        workspaceId: UUID,
        onUpdate: @escaping (String) -> Void,
        onComplete: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        // 获取设置
        let settings = SettingsManager.shared.loadSettings()
        
        // 检查API密钥
        guard !settings.apiKey.isEmpty else {
            onError(APIError.apiKeyMissing)
            return
        }
        
        // 创建URL
        guard let url = URL(string: "\(settings.apiEndpoint)/chat/completions") else {
            onError(APIError.invalidURL)
            return
        }
        
        // 创建请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(settings.apiKey)", forHTTPHeaderField: "Authorization")
        
        // 创建请求体，启用流式响应
        let requestBody = ChatCompletionRequest(
            model: settings.selectedModel,
            messages: [
                ChatCompletionRequest.Message(role: "system", content: "你是一个H5页面生成助手，会根据用户的描述生成HTML代码。请用markdown格式返回代码，使用```html作为代码块开始，```作为代码块结束。"),
                ChatCompletionRequest.Message(role: "user", content: message)
            ],
            temperature: 0.7,
            stream: true
        )
        
        // 编码请求体
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(requestBody)
        } catch {
            onError(APIError.unknownError(error))
            return
        }
        
        // 使用数组缓冲区来减少字符串连接操作
        var responseChunks: [String] = []
        // 线程同步队列
        let syncQueue = DispatchQueue(label: "com.quickGen.bffservice.response", qos: .userInitiated)
        
        // 创建流式任务
        self.streamTask = urlSession.dataTask(with: request) { [weak self] data, response, error in
            guard let _ = self else { return }
            
            // 处理错误
            if let error = error {
                DispatchQueue.main.async {
                    onError(APIError.unknownError(error))
                }
                return
            }
            
            // 检查HTTP响应
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    onError(APIError.invalidResponse)
                }
                return
            }
            
            // 检查状态码
            guard (200..<300).contains(httpResponse.statusCode) else {
                var errorMessage = "HTTP错误: \(httpResponse.statusCode)"
                if let data = data,
                   let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorObj = errorJson["error"] as? [String: Any],
                   let apiErrorMessage = errorObj["message"] as? String {
                    errorMessage = apiErrorMessage
                }
                
                DispatchQueue.main.async {
                    onError(APIError.serverError(errorMessage))
                }
                return
            }
            
            // 处理数据
            guard let data = data else {
                DispatchQueue.main.async {
                    onError(APIError.noData)
                }
                return
            }
            
            // 处理流式响应
            guard let text = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    onError(APIError.decodingError(NSError(domain: "BFFService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法解码响应数据"])))
                }
                return
            }
            
            let lines = text.components(separatedBy: "\n\n")
            var isCompleted = false
            
            for line in lines {
                // 如果已经完成，不再处理后续行
                if isCompleted { break }
                
                if line.hasPrefix("data: ") {
                    let jsonStr = line.dropFirst(6) // 移除 "data: " 前缀
                    
                    // 判断是否是 [DONE] 标记
                    if jsonStr == "[DONE]" {
                        syncQueue.async {
                            let fullResponse = responseChunks.joined()
                            DispatchQueue.main.async {
                                onComplete(fullResponse)
                            }
                        }
                        isCompleted = true
                        continue
                    }
                    
                    // 解析JSON
                    if let jsonData = String(jsonStr).data(using: .utf8),
                       let streamResponse = try? JSONDecoder().decode(ChatCompletionStreamResponse.self, from: jsonData) {
                        
                        if let choice = streamResponse.choices?.first, let content = choice.delta?.content {
                            syncQueue.async {
                                // 添加到缓冲区
                                responseChunks.append(content)
                                let currentResponse = responseChunks.joined()
                                
                                DispatchQueue.main.async {
                                    onUpdate(currentResponse)
                                }
                            }
                        }
                        
                        // 检查是否完成
                        if let choice = streamResponse.choices?.first, choice.finishReason == "stop" {
                            syncQueue.async {
                                let fullResponse = responseChunks.joined()
                                DispatchQueue.main.async {
                                    onComplete(fullResponse)
                                }
                            }
                            isCompleted = true
                        }
                    }
                }
            }
            
            // 如果没有完成标记但数据处理完毕
            if !isCompleted && !lines.isEmpty {
                syncQueue.async {
                    let fullResponse = responseChunks.joined()
                    DispatchQueue.main.async {
                        onComplete(fullResponse)
                    }
                }
            }
        }
        
        // 开始任务
        self.streamTask?.resume()
    }
    
    /// 取消所有正在进行的请求
    func cancelOngoingRequests() {
        streamTask?.cancel()
        streamTask = nil
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
} 