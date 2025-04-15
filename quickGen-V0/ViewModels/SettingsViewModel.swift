import Foundation
import Combine
import SwiftUI

class SettingsViewModel: ObservableObject {
    // API设置
    @Published var apiEndpoint: String = "https://api.openai.com/v1"
    @Published var apiKey: String = ""
    @Published var isApiKeyVisible: Bool = false
    
    // 应用外观设置
    @Published var appearance: AppAppearance = .system
    
    // 用户名称
    @Published var user_name: String = "用户"
    
    // 模型设置
    @Published var availableModels: [String] = []
    @Published var selectedModel: String = ""
    @Published var newModelName: String = ""
    @Published var showingAddModelAlert: Bool = false
    @Published var showingUserNameAlert: Bool = false
    
    // 设置管理器
    private let settingsManager: SettingsManagerProtocol
    
    // 取消订阅令牌
    private var cancellables = Set<AnyCancellable>()
    
    init(settingsManager: SettingsManagerProtocol = SettingsManager.shared) {
        self.settingsManager = settingsManager
        
        // 加载设置
        loadSettings()
        
        // 订阅设置变化
        settingsManager.settingsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] settings in
                self?.updateViewModelFromSettings(settings)
            }
            .store(in: &cancellables)
    }
    
    // 加载保存的设置
    func loadSettings() {
        let settings = settingsManager.loadSettings()
        updateViewModelFromSettings(settings)
    }
    
    // 保存设置
    func saveSettings() {
        var settings = settingsManager.loadSettings()
        settings.apiEndpoint = apiEndpoint
        settings.apiKey = apiKey
        settings.appearance = convertAppAppearanceToAppearanceSetting(appearance)
        settings.availableModels = availableModels
        settings.selectedModel = selectedModel
        
        _ = settingsManager.saveSettings(settings)
    }
    
    // 添加新模型
    func addCustomModel() {
        guard !newModelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let trimmedName = newModelName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 如果模型名称不在列表中，则添加
        if !availableModels.contains(trimmedName) {
            availableModels.append(trimmedName)
            saveSettings()
        }
        
        // 重置新模型名称并关闭提示框
        newModelName = ""
        showingAddModelAlert = false
    }
    
    // 更新选中的模型
    func updateSelectedModel() {
        saveSettings()
    }
    
    // 切换API密钥可见性
    func toggleApiKeyVisibility() {
        isApiKeyVisible.toggle()
    }
    
    // 重置所有设置到默认值
    func resetToDefaults() {
        if settingsManager.resetSettings() {
            loadSettings()
        }
    }
    
    // 从AppSettings更新ViewModel的属性
    private func updateViewModelFromSettings(_ settings: AppSettings) {
        apiEndpoint = settings.apiEndpoint
        apiKey = settings.apiKey
        appearance = convertAppearanceSettingToAppAppearance(settings.appearance)
        availableModels = settings.availableModels
        selectedModel = settings.selectedModel
    }
    
    // 转换AppAppearance到AppearanceSetting
    private func convertAppAppearanceToAppearanceSetting(_ appAppearance: AppAppearance) -> AppearanceSetting {
        switch appAppearance {
        case .system:
            return .system
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    // 转换AppearanceSetting到AppAppearance
    private func convertAppearanceSettingToAppAppearance(_ appearanceSetting: AppearanceSetting) -> AppAppearance {
        switch appearanceSetting {
        case .system:
            return .system
        case .light:
            return .light
        case .dark:
            return .dark
        }
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
