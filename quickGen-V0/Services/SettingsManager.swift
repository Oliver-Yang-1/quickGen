import Foundation
import Combine

/// 设置管理器协议
protocol SettingsManagerProtocol {
    /// 加载设置
    func loadSettings() -> AppSettings
    
    /// 保存设置
    func saveSettings(_ settings: AppSettings) -> Bool
    
    /// 重置设置为默认值
    func resetSettings() -> Bool
    
    /// 设置发生变化的发布者
    var settingsPublisher: AnyPublisher<AppSettings, Never> { get }
}

/// 使用UserDefaults实现的设置管理器
class SettingsManager: SettingsManagerProtocol {
    // MARK: - 单例
    
    /// 共享实例
    static let shared = SettingsManager()
    
    // MARK: - 常量
    
    /// UserDefaults中存储设置的键
    private let settingsKey = "quickGenAppSettings"
    
    // MARK: - 属性
    
    /// 缓存的当前设置
    private var currentSettings = AppSettings()
    
    /// 设置发生变化的主题
    private let settingsSubject = PassthroughSubject<AppSettings, Never>()
    
    /// 设置发生变化的发布者（公开为AnyPublisher）
    var settingsPublisher: AnyPublisher<AppSettings, Never> {
        return settingsSubject.eraseToAnyPublisher()
    }
    
    // MARK: - 初始化
    
    private init() {
        // 加载设置或使用默认值
        currentSettings = loadSettingsFromUserDefaults()
    }
    
    // MARK: - 公共方法
    
    /// 加载设置
    func loadSettings() -> AppSettings {
        currentSettings = loadSettingsFromUserDefaults()
        return currentSettings
    }
    
    /// 保存设置
    func saveSettings(_ settings: AppSettings) -> Bool {
        var settingsToSave = settings
        settingsToSave.updateModificationDate()
        
        let success = saveSettingsToUserDefaults(settingsToSave)
        
        if success {
            currentSettings = settingsToSave
            // 通知订阅者设置已更改
            settingsSubject.send(currentSettings)
        }
        
        return success
    }
    
    /// 重置设置为默认值
    func resetSettings() -> Bool {
        let defaultSettings = AppSettings()
        let success = saveSettingsToUserDefaults(defaultSettings)
        
        if success {
            currentSettings = defaultSettings
            // 通知订阅者设置已重置
            settingsSubject.send(currentSettings)
        }
        
        return success
    }
    
    // MARK: - 私有方法
    
    /// 从UserDefaults加载设置
    private func loadSettingsFromUserDefaults() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: settingsKey) else {
            print("SettingsManager: 未找到保存的设置，使用默认值")
            return AppSettings()
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let settings = try decoder.decode(AppSettings.self, from: data)
            print("SettingsManager: 设置已成功加载")
            return settings
        } catch {
            print("SettingsManager: 解码设置时出错: \(error.localizedDescription)")
            return AppSettings()
        }
    }
    
    /// 保存设置到UserDefaults
    private func saveSettingsToUserDefaults(_ settings: AppSettings) -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(settings)
            UserDefaults.standard.set(data, forKey: settingsKey)
            print("SettingsManager: 设置已成功保存")
            return true
        } catch {
            print("SettingsManager: 编码设置时出错: \(error.localizedDescription)")
            return false
        }
    }
} 