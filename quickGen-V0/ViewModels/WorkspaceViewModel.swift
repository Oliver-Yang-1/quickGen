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
    
    // 工作区数据管理器
    private let workspaceDataManager: WorkspaceDataManager
    // BFF服务
    // private let bffService: BFFService
    
    // 生成的HTML代码
    private var generatedHTML: String? {
        didSet {
            workspace.generatedHTML = generatedHTML
            saveWorkspace()
        }
    }
    
    init(workspace: Workspace, workspaceDataManager: WorkspaceDataManager = FileSystemWorkspaceDataManager.shared) {
        self.workspace = workspace
        self.workspaceDataManager = workspaceDataManager
        // self.bffService = bffService
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
        
        // 调用AI生成回复
        generateResponse(to: input)
    }
    
    // 生成AI回复
    private func generateResponse(to userMessage: String) {
        isLoading = true
        errorMessage = nil
        
        // 模拟API请求延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // 模拟API请求
            // 在实际应用中，这里应该调用BFF服务
            // self.bffService.sendPrompt(prompt: userMessage, workspaceId: self.workspace.id) { result in
            //    switch result {
            //    case .success(let response):
            //        // 处理成功响应
            //    case .failure(let error):
            //        // 处理错误
            //    }
            // }
            
            // 模拟API请求 - 目前使用模拟数据
            if Bool.random() && userMessage.contains("错误") {
                // 模拟错误
                self.handleError("连接超时，请稍后再试")
                return
            }
            
            // 模拟AI回复
            let responseContent = "我已根据你的描述生成了H5页面。\n\n```html\n<!DOCTYPE html>\n<html>\n<head>\n  <title>生成的页面</title>\n  <style>\n    body { font-family: Arial, sans-serif; margin: 0; padding: 20px; }\n    .container { max-width: 800px; margin: 0 auto; }\n    h1 { color: #333; }\n    .button { background-color: #4CAF50; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; }\n    .button:hover { background-color: #45a049; }\n  </style>\n</head>\n<body>\n  <div class=\"container\">\n    <h1>你好，这是根据描述生成的页面</h1>\n    <p>这是一个简单的演示页面，根据你的要求生成。</p>\n    <button class=\"button\">点击我</button>\n  </div>\n</body>\n</html>\n```"
            
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
            
            self.isLoading = false
            self.updateLastModifiedDate()
        }
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
                generateResponse(to: lastUserMessage.content)
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