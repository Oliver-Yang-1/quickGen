import Foundation
import Combine

// WorkspaceDataManager协议定义
protocol WorkspaceDataManager {
    // 工作区操作
    func fetchWorkspaces() -> [Workspace]
    func createWorkspace(name: String) -> Workspace
    func saveWorkspace(_ workspace: Workspace)
    func deleteWorkspace(_ workspace: Workspace) -> Bool
    func renameWorkspace(_ workspace: Workspace, to newName: String) -> Bool
    
    // 聊天消息操作
    func fetchChatHistory(forWorkspace workspaceId: UUID) -> [ChatMessage]
    func saveChatMessage(_ message: ChatMessage, toWorkspace workspaceId: UUID) -> Bool
    func clearChatHistory(forWorkspace workspaceId: UUID) -> Bool
    
    // 生成代码操作
    func getLatestGeneratedCode(forWorkspace workspaceId: UUID) -> GeneratedCode?
    func saveGeneratedCode(_ code: GeneratedCode, forWorkspace workspaceId: UUID) -> Bool
}

// 工作区数据管理器的文件系统实现
class FileSystemWorkspaceDataManager: WorkspaceDataManager {
    // 单例实例
    static let shared = FileSystemWorkspaceDataManager()
    
    // 应用文档目录下的工作区目录
    private let workspacesDirectoryName = "workspaces"
    
    // 文件管理器
    private let fileManager = FileManager.default
    
    // 私有初始化方法，确保使用单例
    private init() {
        // 确保工作区目录存在
        createWorkspacesDirectoryIfNeeded()
    }
    
    // MARK: - 工作区目录管理
    
    // 获取工作区根目录的URL
    private func getWorkspacesDirectoryURL() -> URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent(workspacesDirectoryName)
    }
    
    // 确保工作区目录存在
    private func createWorkspacesDirectoryIfNeeded() {
        let workspacesDirectory = getWorkspacesDirectoryURL()
        
        if !fileManager.fileExists(atPath: workspacesDirectory.path) {
            do {
                try fileManager.createDirectory(at: workspacesDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("创建工作区目录失败: \(error.localizedDescription)")
            }
        }
    }
    
    // 获取特定工作区的目录URL
    private func getWorkspaceDirectoryURL(forWorkspace workspace: Workspace) -> URL {
        return getWorkspacesDirectoryURL().appendingPathComponent(workspace.getFolderName())
    }
    
    // 创建工作区目录
    private func createWorkspaceDirectory(forWorkspace workspace: Workspace) -> Bool {
        let workspaceDirectory = getWorkspaceDirectoryURL(forWorkspace: workspace)
        
        do {
            try fileManager.createDirectory(at: workspaceDirectory, withIntermediateDirectories: true, attributes: nil)
            
            // 创建子目录：聊天记录
            let chatDirectory = workspaceDirectory.appendingPathComponent("chat")
            try fileManager.createDirectory(at: chatDirectory, withIntermediateDirectories: true, attributes: nil)
            
            // 创建子目录：生成的代码
            let codeDirectory = workspaceDirectory.appendingPathComponent("code")
            try fileManager.createDirectory(at: codeDirectory, withIntermediateDirectories: true, attributes: nil)
            
            return true
        } catch {
            print("创建工作区目录失败: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - 工作区元数据管理
    
    // 获取工作区元数据文件URL
    private func getWorkspaceMetadataURL(forWorkspace workspace: Workspace) -> URL {
        return getWorkspaceDirectoryURL(forWorkspace: workspace).appendingPathComponent("metadata.json")
    }
    
    // 保存工作区元数据
    private func saveWorkspaceMetadata(_ workspace: Workspace) -> Bool {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(workspace)
            let metadataURL = getWorkspaceMetadataURL(forWorkspace: workspace)
            try data.write(to: metadataURL)
            return true
        } catch {
            print("保存工作区元数据失败: \(error.localizedDescription)")
            return false
        }
    }
    
    // 读取工作区元数据
    private func loadWorkspaceMetadata(fromURL url: URL) -> Workspace? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let data = try Data(contentsOf: url)
            let workspace = try decoder.decode(Workspace.self, from: data)
            return workspace
        } catch {
            print("读取工作区元数据失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - 聊天消息管理
    
    // 获取聊天消息目录URL
    private func getChatDirectoryURL(forWorkspace workspace: Workspace) -> URL {
        return getWorkspaceDirectoryURL(forWorkspace: workspace).appendingPathComponent("chat")
    }
    
    // 获取单个聊天消息文件URL
    private func getChatMessageURL(forMessageId messageId: UUID, inWorkspace workspace: Workspace) -> URL {
        return getChatDirectoryURL(forWorkspace: workspace).appendingPathComponent("\(messageId.uuidString).json")
    }
    
    // 保存单个聊天消息
    private func saveChatMessageToFile(_ message: ChatMessage, inWorkspace workspace: Workspace) -> Bool {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(message)
            let messageURL = getChatMessageURL(forMessageId: message.id, inWorkspace: workspace)
            try data.write(to: messageURL)
            return true
        } catch {
            print("保存聊天消息失败: \(error.localizedDescription)")
            return false
        }
    }
    
    // 读取单个聊天消息
    private func loadChatMessage(fromURL url: URL) -> ChatMessage? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let data = try Data(contentsOf: url)
            let message = try decoder.decode(ChatMessage.self, from: data)
            return message
        } catch {
            print("读取聊天消息失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - 生成代码管理
    
    // 获取生成代码目录URL
    private func getCodeDirectoryURL(forWorkspace workspace: Workspace) -> URL {
        return getWorkspaceDirectoryURL(forWorkspace: workspace).appendingPathComponent("code")
    }
    
    // 获取单个生成代码文件URL
    private func getGeneratedCodeURL(forCodeId codeId: UUID, inWorkspace workspace: Workspace) -> URL {
        return getCodeDirectoryURL(forWorkspace: workspace).appendingPathComponent("\(codeId.uuidString).json")
    }
    
    // 获取最新生成代码的索引文件URL
    private func getLatestCodeIndexURL(forWorkspace workspace: Workspace) -> URL {
        return getCodeDirectoryURL(forWorkspace: workspace).appendingPathComponent("latest.txt")
    }
    
    // 保存单个生成代码
    private func saveGeneratedCodeToFile(_ code: GeneratedCode, inWorkspace workspace: Workspace) -> Bool {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            // 保存代码文件
            let data = try encoder.encode(code)
            let codeURL = getGeneratedCodeURL(forCodeId: code.id, inWorkspace: workspace)
            try data.write(to: codeURL)
            
            // 更新最新代码索引
            let latestIndexURL = getLatestCodeIndexURL(forWorkspace: workspace)
            try code.id.uuidString.write(to: latestIndexURL, atomically: true, encoding: .utf8)
            
            return true
        } catch {
            print("保存生成代码失败: \(error.localizedDescription)")
            return false
        }
    }
    
    // 读取单个生成代码
    private func loadGeneratedCode(fromURL url: URL) -> GeneratedCode? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let data = try Data(contentsOf: url)
            let code = try decoder.decode(GeneratedCode.self, from: data)
            return code
        } catch {
            print("读取生成代码失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - WorkspaceDataManager协议实现
    
    // 获取所有工作区
    func fetchWorkspaces() -> [Workspace] {
        let workspacesDirectory = getWorkspacesDirectoryURL()
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: workspacesDirectory, includingPropertiesForKeys: nil, options: [])
            
            let workspaces = contents
                .filter { $0.hasDirectoryPath }
                .compactMap { workspaceDir -> Workspace? in
                    let metadataURL = workspaceDir.appendingPathComponent("metadata.json")
                    return loadWorkspaceMetadata(fromURL: metadataURL)
                }
                .sorted { $0.lastModifiedDate > $1.lastModifiedDate } // 按最近修改日期排序
            
            return workspaces
        } catch {
            print("获取工作区列表失败: \(error.localizedDescription)")
            return []
        }
    }
    
    // 创建新工作区
    func createWorkspace(name: String) -> Workspace {
        let workspace = Workspace(name: name)
        
        // 创建工作区目录结构
        let success = createWorkspaceDirectory(forWorkspace: workspace)
        
        if success {
            // 保存工作区元数据
            saveWorkspaceMetadata(workspace)
        }
        
        return workspace
    }
    
    // 保存工作区
    func saveWorkspace(_ workspace: Workspace) {
        saveWorkspaceMetadata(workspace)
    }
    
    // 删除工作区
    func deleteWorkspace(_ workspace: Workspace) -> Bool {
        let workspaceDirectory = getWorkspaceDirectoryURL(forWorkspace: workspace)
        
        do {
            try fileManager.removeItem(at: workspaceDirectory)
            return true
        } catch {
            print("删除工作区失败: \(error.localizedDescription)")
            return false
        }
    }
    
    // 重命名工作区
    func renameWorkspace(_ workspace: Workspace, to newName: String) -> Bool {
        var updatedWorkspace = workspace
        updatedWorkspace.name = newName
        updatedWorkspace.lastModifiedDate = Date()
        
        return saveWorkspaceMetadata(updatedWorkspace)
    }
    
    // 获取工作区的聊天历史
    func fetchChatHistory(forWorkspace workspaceId: UUID) -> [ChatMessage] {
        let workspace = Workspace(id: workspaceId, name: "") // 临时工作区对象，仅用于构建路径
        let chatDirectory = getChatDirectoryURL(forWorkspace: workspace)
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: chatDirectory, includingPropertiesForKeys: nil, options: [])
            
            let messages = contents
                .filter { $0.pathExtension == "json" }
                .compactMap { loadChatMessage(fromURL: $0) }
                .sorted { $0.timestamp < $1.timestamp } // 按时间顺序排序
            
            return messages
        } catch {
            print("获取聊天历史失败: \(error.localizedDescription)")
            return []
        }
    }
    
    // 保存聊天消息
    func saveChatMessage(_ message: ChatMessage, toWorkspace workspaceId: UUID) -> Bool {
        let workspace = Workspace(id: workspaceId, name: "") // 临时工作区对象，仅用于构建路径
        return saveChatMessageToFile(message, inWorkspace: workspace)
    }
    
    // 清除聊天历史
    func clearChatHistory(forWorkspace workspaceId: UUID) -> Bool {
        let workspace = Workspace(id: workspaceId, name: "") // 临时工作区对象，仅用于构建路径
        let chatDirectory = getChatDirectoryURL(forWorkspace: workspace)
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: chatDirectory, includingPropertiesForKeys: nil, options: [])
            
            for file in contents {
                try fileManager.removeItem(at: file)
            }
            
            return true
        } catch {
            print("清除聊天历史失败: \(error.localizedDescription)")
            return false
        }
    }
    
    // 获取最新生成的代码
    func getLatestGeneratedCode(forWorkspace workspaceId: UUID) -> GeneratedCode? {
        let workspace = Workspace(id: workspaceId, name: "") // 临时工作区对象，仅用于构建路径
        let latestIndexURL = getLatestCodeIndexURL(forWorkspace: workspace)
        
        guard fileManager.fileExists(atPath: latestIndexURL.path) else {
            return nil
        }
        
        do {
            let latestCodeId = try String(contentsOf: latestIndexURL, encoding: .utf8)
            let codeURL = getCodeDirectoryURL(forWorkspace: workspace).appendingPathComponent("\(latestCodeId).json")
            
            return loadGeneratedCode(fromURL: codeURL)
        } catch {
            print("获取最新生成代码失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    // 保存生成的代码
    func saveGeneratedCode(_ code: GeneratedCode, forWorkspace workspaceId: UUID) -> Bool {
        let workspace = Workspace(id: workspaceId, name: "") // 临时工作区对象，仅用于构建路径
        return saveGeneratedCodeToFile(code, inWorkspace: workspace)
    }
} 