import Foundation
import Combine
import SwiftUI

class SettingsViewModel: ObservableObject {
    // API设置
    @Published var openAIKey: String = ""
    @Published var openAIBaseURL: String = "https://api.openai.com/v1"
    @Published var openAIModel: String = "gpt-3.5-turbo"
    
    // 应用外观设置
    @Published var appearance: AppAppearance = .system
    
    // 用户选择的默认模型选项
    @Published var selectedModelIndex: Int = 0
    
    // 可用的模型选项
    let availableModels = ["gpt-3.5-turbo", "gpt-4", "gpt-4-turbo"]
    
    // UserDefaults键
    private let keyOpenAIKey = "openai_api_key"
    private let keyOpenAIBaseURL = "openai_base_url"
    private let keyOpenAIModel = "openai_model"
    private let keyAppearance = "app_appearance"
    
    init() {
        loadSettings()
        
        // 设置当前选中的模型索引
        if let index = availableModels.firstIndex(of: openAIModel) {
            selectedModelIndex = index
        }
    }
    
    // 加载保存的设置
    func loadSettings() {
        let defaults = UserDefaults.standard
        
        openAIKey = defaults.string(forKey: keyOpenAIKey) ?? ""
        openAIBaseURL = defaults.string(forKey: keyOpenAIBaseURL) ?? "https://api.openai.com/v1"
        openAIModel = defaults.string(forKey: keyOpenAIModel) ?? "gpt-3.5-turbo"
        
        let appearanceValue = defaults.integer(forKey: keyAppearance)
        appearance = AppAppearance(rawValue: appearanceValue) ?? .system
    }
    
    // 保存设置
    func saveSettings() {
        let defaults = UserDefaults.standard
        
        defaults.set(openAIKey, forKey: keyOpenAIKey)
        defaults.set(openAIBaseURL, forKey: keyOpenAIBaseURL)
        defaults.set(openAIModel, forKey: keyOpenAIModel)
        defaults.set(appearance.rawValue, forKey: keyAppearance)
    }
    
    // 更新选中的模型
    func updateSelectedModel() {
        openAIModel = availableModels[selectedModelIndex]
        saveSettings()
    }
    
    // 重置所有设置到默认值
    func resetToDefaults() {
        openAIKey = ""
        openAIBaseURL = "https://api.openai.com/v1"
        openAIModel = "gpt-3.5-turbo"
        appearance = .system
        selectedModelIndex = 0
        saveSettings()
    }
}

// 应用外观枚举
enum AppAppearance: Int {
    case system = 0
    case light = 1
    case dark = 2
    
    var name: String {
        switch self {
        case .system:
            return "跟随系统"
        case .light:
            return "浅色模式"
        case .dark:
            return "深色模式"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
} 