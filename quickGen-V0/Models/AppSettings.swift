import Foundation

/// 应用外观设置选项
enum AppearanceSetting: String, Codable {
    case light = "light"
    case dark = "dark"
    case system = "system"
}

/// 应用设置模型，包含所有用户可配置的设置项
struct AppSettings: Codable, Equatable {
    /// 应用外观设置（浅色/深色/系统）
    var appearance: AppearanceSetting = .system
    
    /// API设置
    var apiEndpoint: String = "https://api.openai.com/v1"
    
    /// API密钥
    var apiKey: String = ""
    
    /// 可用的AI模型列表
    var availableModels: [String] = ["gpt-3.5-turbo", "gpt-4", "gpt-4-turbo"]
    
    /// 当前选择的模型
    var selectedModel: String = "gpt-3.5-turbo"
    
    /// 创建日期（记录设置首次创建时间）
    var createdAt: Date = Date()
    
    /// 上次修改日期
    var lastModifiedAt: Date = Date()
    
    /// 判断相等性
    static func == (lhs: AppSettings, rhs: AppSettings) -> Bool {
        return lhs.appearance == rhs.appearance &&
               lhs.apiEndpoint == rhs.apiEndpoint &&
               lhs.apiKey == rhs.apiKey &&
               lhs.availableModels == rhs.availableModels &&
               lhs.selectedModel == rhs.selectedModel
        // 注意：我们不比较日期字段，因为它们可能会自动更新
    }
    
    /// 更新最后修改时间
    mutating func updateModificationDate() {
        self.lastModifiedAt = Date()
    }
    
    /// 添加新模型到可用模型列表
    mutating func addModel(_ model: String) {
        // 如果模型不存在，添加到列表
        if !availableModels.contains(model) {
            availableModels.append(model)
        }
    }
} 