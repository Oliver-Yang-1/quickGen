import Foundation
import SwiftUI
import Combine

/// BFFService测试运行器
/// 允许在应用中运行API测试
class BFFServiceTestRunner: ObservableObject {
    static let shared = BFFServiceTestRunner()
    
    @Published var isRunningTest = false
    @Published var testResults = ""
    @Published var hasError = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    /// 配置测试环境
    private func configureTestEnvironment() -> Bool {
        let testApiKey = "eyJhbGciOiJIUzI1NiIsImtpZCI6IlV6SXJWd1h0dnprLVRvdzlLZWstc0M1akptWXBvX1VaVkxUZlpnMDRlOFUiLCJ0eXAiOiJKV1QifQ.eyJzdWIiOiJ3aW5kb3dzbGl2ZXwzNGUxYjg3YmJhYjc4NDFlIiwic2NvcGUiOiJvcGVuaWQgb2ZmbGluZV9hY2Nlc3MiLCJpc3MiOiJhcGlfa2V5X2lzc3VlciIsImF1ZCI6WyJodHRwczovL25lYml1cy1pbmZlcmVuY2UuZXUuYXV0aDAuY29tL2FwaS92Mi8iXSwiZXhwIjoxODk3NDc5NzYyLCJ1dWlkIjoiYzcyMWY0MDMtODhjZC00ZjIzLThmZjktOTRkMTNjY2Q4YjY5IiwibmFtZSI6ImRlZXBzZWVrIiwiZXhwaXJlc19hdCI6IjIwMzAtMDItMTZUMTM6NDI6NDIrMDAwMCJ9.cg84grNfi_uZHhnvj_SSbpz7RIxfiGqDo1vurEkECaA"
        let testApiUrl = "https://api.studio.nebius.com/v1"
        let testModel = "deepseek-ai/DeepSeek-V3"
        
        // 确保API密钥不为空
        if testApiKey.isEmpty {
            appendToResults("错误：测试API密钥为空", isError: true)
            return false
        }
        
        // 确保API URL正确
        if !testApiUrl.starts(with: "http") {
            appendToResults("错误：API URL无效: \(testApiUrl)", isError: true)
            return false
        }
        
        // 更新应用设置
        let settings = AppSettings(
            appearance: .system,
            apiEndpoint: testApiUrl,
            apiKey: testApiKey,
            availableModels: [testModel],
            selectedModel: testModel
        )
        
        // 保存设置
        if !SettingsManager.shared.saveSettings(settings) {
            appendToResults("错误：无法保存测试设置", isError: true)
            return false
        }
        
        appendToResults("测试环境已配置：")
        appendToResults("API URL: \(testApiUrl)")
        appendToResults("模型: \(testModel)")
        
        return true
    }
    
    /// 运行测试
    func runTest() {
        // 重置测试状态
        testResults = ""
        hasError = false
        isRunningTest = true
        
        appendToResults("开始BFFService测试...")
        
        // 配置测试环境
        guard configureTestEnvironment() else {
            isRunningTest = false
            return
        }
        
        let service = RealBFFService.shared
        let testMessage = "创建一个简单的登录页面，带用户名和密码字段"
        let workspaceId = UUID()
        
        appendToResults("发送消息: \"\(testMessage)\"")
        
        service.sendMessage(testMessage, workspaceId: workspaceId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    
                    self.isRunningTest = false
                    
                    switch completion {
                    case .finished:
                        self.appendToResults("\n请求完成")
                    case .failure(let error):
                        self.hasError = true
                        self.appendToResults("\n请求失败: \(error.localizedDescription)", isError: true)
                        
                        if let apiError = error as? APIError {
                            switch apiError {
                            case .serverError(let message):
                                self.appendToResults("服务器错误: \(message)", isError: true)
                            case .httpError(let code):
                                self.appendToResults("HTTP错误码: \(code)", isError: true)
                            default:
                                self.appendToResults("其他API错误: \(apiError.localizedDescription)", isError: true)
                            }
                        }
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    
                    self.appendToResults("\n收到响应: ")
                    self.appendToResults(response)
                    
                    // 提取HTML代码
                    var htmlCode: String? = nil
                    if let startRange = response.range(of: "```html\n"),
                       let endRange = response.range(of: "```", options: .backwards, range: startRange.upperBound..<response.endIndex) {
                        let startIndex = startRange.upperBound
                        let endIndex = endRange.lowerBound
                        htmlCode = String(response[startIndex..<endIndex])
                    }
                    
                    if let html = htmlCode {
                        self.appendToResults("\n提取的HTML代码:")
                        self.appendToResults(html)
                        self.appendToResults("\n测试成功! ✅")
                    } else {
                        self.appendToResults("\n未能提取HTML代码", isError: true)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// 取消测试
    func cancelTest() {
        RealBFFService.shared.cancelOngoingRequests()
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        isRunningTest = false
        appendToResults("\n测试已取消", isError: true)
    }
    
    /// 添加测试结果
    private func appendToResults(_ text: String, isError: Bool = false) {
        if isError {
            hasError = true
        }
        
        if testResults.isEmpty {
            testResults = text
        } else {
            testResults += "\n\(text)"
        }
    }
}

/// BFFService测试视图
struct BFFServiceTestView: View {
    @StateObject private var testRunner = BFFServiceTestRunner.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                // 测试结果显示区域
                ScrollView {
                    Text(testRunner.testResults)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(testRunner.hasError ? .red : .primary)
                }
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
                .padding()
                
                Spacer()
                
                // 测试控制按钮
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("关闭")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)
                    .disabled(testRunner.isRunningTest)
                    
                    if testRunner.isRunningTest {
                        Button(action: {
                            testRunner.cancelTest()
                        }) {
                            Text("取消测试")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    } else {
                        Button(action: {
                            testRunner.runTest()
                        }) {
                            Text("运行测试")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
            .navigationTitle("BFFService测试")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
} 