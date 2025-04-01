import Foundation
import Combine
import SwiftUI
import WebKit

class WorkspaceViewModel: ObservableObject {
    // 当前工作区
    @Published var workspace: Workspace
    // 聊天消息
    @Published var chatMessages: [ChatMessage] = []
    // 用户输入
    @Published var userInput: String = ""
    // 加载状态
    @Published var isLoading: Bool = false
    // 错误信息
    @Published var errorMessage: String? = nil
    // 是否在预览模式
    @Published var isPreviewMode: Bool = false
    // 当前流式响应的消息ID
    @Published var streamingMessageId: UUID?
    
    // 工作区数据管理器
    private let workspaceDataManager: WorkspaceDataManager
    // BFF服务
    private let bffService: BFFServiceProtocol
    // 取消订阅令牌
    private var cancellables = Set<AnyCancellable>()
    // 是否使用流式响应
    private let useStreamResponse = true
    
    // 生成的HTML代码
    private var generatedHTML: String? {
        didSet {
            workspace.generatedHTML = generatedHTML
            saveWorkspace()
        }
    }
    
    init(workspace: Workspace, 
         workspaceDataManager: WorkspaceDataManager = FileSystemWorkspaceDataManager.shared,
         bffService: BFFServiceProtocol = RealBFFService.shared) {
        self.workspace = workspace
        self.workspaceDataManager = workspaceDataManager
        self.bffService = bffService
        loadChatHistory()
        
        // 加载最新生成的HTML代码
        if let generatedCode = workspaceDataManager.getLatestGeneratedCode(forWorkspace: workspace.id) {
            self.generatedHTML = generatedCode.htmlContent
            self.workspace.generatedHTML = generatedCode.htmlContent
        } else {
            self.generatedHTML = workspace.generatedHTML
        }
    }
    
    // 发送消息
    func sendMessage() {
        guard !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let userMessage = ChatMessage(
            workspaceId: workspace.id,
            sender: .user,
            content: userInput
        )
        
        chatMessages.append(userMessage)
        
        // 保存用户消息
        workspaceDataManager.saveChatMessage(userMessage, toWorkspace: workspace.id)
        
        // 保存用户输入
        let input = userInput
        userInput = ""
        
        // 调用BFF服务生成回复
        if useStreamResponse {
            generateStreamResponse(to: input)
        } else {
            generateResponse(to: input)
        }
    }
    
    // 生成AI流式回复
    private func generateStreamResponse(to userMessage: String) {
        isLoading = true
        errorMessage = nil
        
        // 创建初始的空AI消息
        let aiMessage = ChatMessage(
            workspaceId: workspace.id,
            sender: .ai,
            content: ""
        )
        
        // 记录当前流式消息ID
        streamingMessageId = aiMessage.id
        
        // 添加初始空消息到聊天记录
        chatMessages.append(aiMessage)
        
        // 调用BFF服务
        bffService.sendStreamMessage(
            userMessage,
            workspaceId: workspace.id,
            onUpdate: { [weak self] partialResponse in
                guard let self = self, let index = self.findMessageIndex(id: aiMessage.id) else { return }
                
                DispatchQueue.main.async {
                    // 更新消息内容
                    self.chatMessages[index].content = partialResponse
                    
                    // 尝试提取HTML代码
                    if let htmlCode = self.extractHTMLCode(from: partialResponse) {
                        self.generatedHTML = htmlCode
                    }
                }
            },
            onComplete: { [weak self] finalResponse in
                guard let self = self, let index = self.findMessageIndex(id: aiMessage.id) else { return }
                
                DispatchQueue.main.async {
                    // 更新最终消息内容
                    self.chatMessages[index].content = finalResponse
                    
                    // 保存完整的AI消息
                    self.workspaceDataManager.saveChatMessage(self.chatMessages[index], toWorkspace: self.workspace.id)
                    
                    // 提取HTML代码并保存
                    if let htmlCode = self.extractHTMLCode(from: finalResponse) {
                        self.generatedHTML = htmlCode
                        
                        // 保存生成的代码
                        let generatedCode = GeneratedCode(
                            workspaceId: self.workspace.id,
                            htmlContent: htmlCode
                        )
                        self.workspaceDataManager.saveGeneratedCode(generatedCode, forWorkspace: self.workspace.id)
                    }
                    
                    self.isLoading = false
                    self.streamingMessageId = nil
                    self.updateLastModifiedDate()
                }
            },
            onError: { [weak self] error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.handleError("发送消息失败: \(error.localizedDescription)")
                    self.streamingMessageId = nil
                }
            }
        )
    }
    
    // 查找消息索引
    private func findMessageIndex(id: UUID) -> Int? {
        return chatMessages.firstIndex(where: { $0.id == id })
    }
    
    // 生成AI回复
    private func generateResponse(to userMessage: String) {
        isLoading = true
        errorMessage = nil
        
        // 调用BFF服务
        bffService.sendMessage(userMessage, workspaceId: workspace.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    
                    self.isLoading = false
                    
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self.handleError("发送消息失败: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] responseContent in
                    guard let self = self else { return }
                    
                    let aiMessage = ChatMessage(
                        workspaceId: self.workspace.id,
                        sender: .ai,
                        content: responseContent
                    )
                    
                    self.chatMessages.append(aiMessage)
                    
                    // 保存AI消息
                    self.workspaceDataManager.saveChatMessage(aiMessage, toWorkspace: self.workspace.id)
                    
                    // 提取HTML代码
                    if let htmlCode = self.extractHTMLCode(from: responseContent) {
                        self.generatedHTML = htmlCode
                        
                        // 保存生成的代码
                        let generatedCode = GeneratedCode(
                            workspaceId: self.workspace.id,
                            htmlContent: htmlCode
                        )
                        self.workspaceDataManager.saveGeneratedCode(generatedCode, forWorkspace: self.workspace.id)
                    }
                    
                    self.updateLastModifiedDate()
                }
            )
            .store(in: &cancellables)
    }
    
    // 从AI回复中提取HTML代码
    private func extractHTMLCode(from text: String) -> String? {
        // 简单的代码提取逻辑 - 查找```html和```之间的内容
        guard let startRange = text.range(of: "```html\n"),
              let endRange = text.range(of: "```", options: .backwards) else {
            return nil
        }
        
        let startIndex = startRange.upperBound
        let endIndex = endRange.lowerBound
        
        guard startIndex < endIndex else {
            return nil
        }
        
        return String(text[startIndex..<endIndex])
    }
    
    // 处理错误
    private func handleError(_ message: String) {
        isLoading = false
        errorMessage = message
        
        let errorMessage = ChatMessage(
            workspaceId: workspace.id,
            sender: .ai,
            content: "错误: \(message)",
            isError: true
        )
        
        chatMessages.append(errorMessage)
        
        // 保存错误消息
        workspaceDataManager.saveChatMessage(errorMessage, toWorkspace: workspace.id)
    }
    
    // 运行生成
    func runGeneration() {
        if isPreviewMode {
            // 如果在预览模式下，先切换回聊天模式再生成
            isPreviewMode = false
        }
        
        if userInput.isEmpty {
            // 如果没有新的输入，但有历史消息，使用最后一条用户消息
            if let lastUserMessage = chatMessages.last(where: { $0.sender == .user }) {
                if useStreamResponse {
                    generateStreamResponse(to: lastUserMessage.content)
                } else {
                    generateResponse(to: lastUserMessage.content)
                }
            } else {
                errorMessage = "请输入描述内容"
            }
        } else {
            sendMessage()
        }
    }
    
    // 切换预览模式
    func togglePreviewMode() {
        isPreviewMode.toggle()
    }
    
    // 复制生成的代码
    func copyGeneratedCode() {
        if let html = generatedHTML {
            UIPasteboard.general.string = html
        }
    }
    
    // 导出HTML文件
    func exportHTML() {
        // 在实际应用中，这里应该实现文件导出功能
        print("导出HTML文件")
    }
    
    // 更新最后修改时间
    private func updateLastModifiedDate() {
        workspace.lastModifiedDate = Date()
        saveWorkspace()
    }
    
    // 保存工作区
    private func saveWorkspace() {
        workspaceDataManager.saveWorkspace(workspace)
    }
    
    // 加载聊天历史
    private func loadChatHistory() {
        chatMessages = workspaceDataManager.fetchChatHistory(forWorkspace: workspace.id)
    }
    
    // 清除聊天历史
    func clearChatHistory() -> Bool {
        let success = workspaceDataManager.clearChatHistory(forWorkspace: workspace.id)
        if success {
            chatMessages = []
        }
        return success
    }
} 