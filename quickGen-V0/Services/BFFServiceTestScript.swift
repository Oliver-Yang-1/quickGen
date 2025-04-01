import Foundation
import Combine

/// BFFService测试脚本
/// 用于从控制台或Playground中快速测试BFFService功能
class BFFServiceTestScript {
    private var cancellables = Set<AnyCancellable>()
    
    /// 运行测试
    func run() {
        print("=====================================================")
        print("BFFService测试脚本")
        print("=====================================================")
        
        // 配置测试环境
        configureEnvironment()
        
        // 创建BFFService实例
        let service = RealBFFService.shared
        
        // 准备测试数据
        let testMessage = "创建一个简单的登录页面，带用户名和密码字段，页面有Logo和提交按钮"
        let workspaceId = UUID()
        
        print("发送消息: \(testMessage)")
        print("等待响应...")
        
        // 发送测试请求
        service.sendMessage(testMessage, workspaceId: workspaceId)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("\n请求完成")
                        print("=====================================================")
                    case .failure(let error):
                        print("\n请求失败: \(error.localizedDescription)")
                        
                        if let apiError = error as? APIError {
                            switch apiError {
                            case .serverError(let message):
                                print("服务器错误: \(message)")
                            case .httpError(let code):
                                print("HTTP错误码: \(code)")
                            default:
                                print("API错误类型: \(apiError)")
                            }
                        }
                        
                        print("=====================================================")
                    }
                    
                    // 等待一下，确保输出完整显示
                    Thread.sleep(forTimeInterval: 1.0)
                    exit(0)
                },
                receiveValue: { response in
                    print("\n收到响应:")
                    print(response)
                    
                    // 提取HTML代码
                    if let htmlCode = self.extractHTMLCode(from: response) {
                        print("\n成功提取HTML代码:")
                        print(htmlCode)
                        print("\n测试成功! ✅")
                    } else {
                        print("\n未能提取HTML代码，但接收到了响应。请检查响应格式。")
                    }
                }
            )
            .store(in: &cancellables)
        
        // 保持脚本运行，直到请求完成
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 60))
    }
    
    /// 配置测试环境
    private func configureEnvironment() {
        print("配置测试环境...")
        
        let testApiKey = "eyJhbGciOiJIUzI1NiIsImtpZCI6IlV6SXJWd1h0dnprLVRvdzlLZWstc0M1akptWXBvX1VaVkxUZlpnMDRlOFUiLCJ0eXAiOiJKV1QifQ.eyJzdWIiOiJ3aW5kb3dzbGl2ZXwzNGUxYjg3YmJhYjc4NDFlIiwic2NvcGUiOiJvcGVuaWQgb2ZmbGluZV9hY2Nlc3MiLCJpc3MiOiJhcGlfa2V5X2lzc3VlciIsImF1ZCI6WyJodHRwczovL25lYml1cy1pbmZlcmVuY2UuZXUuYXV0aDAuY29tL2FwaS92Mi8iXSwiZXhwIjoxODk3NDc5NzYyLCJ1dWlkIjoiYzcyMWY0MDMtODhjZC00ZjIzLThmZjktOTRkMTNjY2Q4YjY5IiwibmFtZSI6ImRlZXBzZWVrIiwiZXhwaXJlc19hdCI6IjIwMzAtMDItMTZUMTM6NDI6NDIrMDAwMCJ9.cg84grNfi_uZHhnvj_SSbpz7RIxfiGqDo1vurEkECaA"
        let testApiUrl = "https://api.studio.nebius.com/v1"
        let testModel = "deepseek-ai/DeepSeek-V3"
        
        // 更新应用设置
        let settings = AppSettings(
            appearance: .system,
            apiEndpoint: testApiUrl,
            apiKey: testApiKey,
            availableModels: [testModel],
            selectedModel: testModel
        )
        
        // 保存设置
        if SettingsManager.shared.saveSettings(settings) {
            print("测试环境配置成功")
            print("API URL: \(testApiUrl)")
            print("模型: \(testModel)")
        } else {
            print("警告: 测试环境配置可能失败")
        }
    }
    
    /// 从回复中提取HTML代码
    private func extractHTMLCode(from text: String) -> String? {
        guard let startRange = text.range(of: "```html\n"),
              let endRange = text.range(of: "```", options: .backwards, range: startRange.upperBound..<text.endIndex) else {
            return nil
        }
        
        let startIndex = startRange.upperBound
        let endIndex = endRange.lowerBound
        
        guard startIndex < endIndex else {
            return nil
        }
        
        return String(text[startIndex..<endIndex])
    }
    
    /// 启动测试的静态方法
    static func startTest() {
        let tester = BFFServiceTestScript()
        tester.run()
    }
}

// 控制台运行示例 - 注释掉顶层执行代码
// let tester = BFFServiceTestScript()
// tester.run()

// 如果需要在控制台测试，可以调用这个静态方法
// BFFServiceTestScript.startTest() 