//
//  quickGen_V0App.swift
//  quickGen-V0
//
//  Created by Oliver Yang on 2025/3/28.
//

import SwiftUI

@main
struct quickGen_V0App: App {
    init() {
        // 在应用启动时预加载设置
        _ = SettingsManager.shared.loadSettings()
        print("应用启动：设置已预加载")
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(getPreferredColorScheme())
        }
    }
    
    // 根据应用设置获取颜色方案
    private func getPreferredColorScheme() -> ColorScheme? {
        let settings = SettingsManager.shared.loadSettings()
        switch settings.appearance {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil // 使用系统默认值
        }
    }
}
