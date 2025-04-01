# BFFService功能实现方案

## 整体架构

我将基于MVVM架构设计BFFService，使其作为应用与后端服务之间的桥梁。这个服务将处理与AI API的所有交互，同时确保聊天消息能够持久化存储并与各个工作区一一对应。

## 网络请求框架选择

对于网络请求，我推荐使用Swift原生的**URLSession**搭配**Combine框架**：

1. **URLSession**：
   - 是iOS原生的网络请求框架，无需引入第三方依赖
   - 支持异步请求、上传/下载任务、后台请求等功能
   - 与Swift的async/await语法完美结合

2. **Combine**：
   - Apple官方提供的响应式编程框架
   - 可以将网络请求包装为Publisher，便于处理异步响应
   - 与SwiftUI的数据流理念一致，实现状态更新的自动传播

这种组合的好处是完全使用原生技术栈，减少第三方依赖，同时提供现代化的异步请求处理方式。

## BFFService接口设计

```swift
protocol BFFServiceProtocol {
    /// 发送消息到BFF服务
    /// - Parameters:
    ///   - message: 用户消息内容
    ///   - workspaceId: 工作区ID
    ///   - settings: API设置（密钥等）
    /// - Returns: 包含AI响应的Publisher
    func sendMessage(_ message: String, 
                     workspaceId: UUID, 
                     settings: AppSettings) -> AnyPublisher<ChatMessage, Error>
    
    /// 取消当前进行的请求
    func cancelOngoingRequests()
}
```

## BFFService实现流程

1. **请求准备阶段**：
   - 根据AppSettings中的配置（apiEndpoint、apiKey、selectedModel）构建请求
   - 将用户消息格式化为API所需的JSON格式
   - 设置请求头（Authorization、Content-Type等）

2. **请求发送与响应处理**：
   - 使用URLSession.dataTaskPublisher发送请求
   - 使用Combine处理异步响应流
   - 解码API返回的JSON数据为本地模型

3. **错误处理**：
   - 网络错误（连接问题、超时等）
   - API错误（验证失败、配额超限等）
   - 解码错误（格式不匹配等）

4. **结果持久化**：
   - 将成功的消息交给WorkspaceDataManager保存
   - 确保消息与对应工作区关联

## 消息持久化方案

针对聊天记录的持久化，我将采用已有的`FileSystemWorkspaceDataManager`进行扩展：

1. **文件结构设计**：
   ```
   /工作区目录/{workspace_id}/
      ├── metadata.json     # 工作区元数据
      ├── chat/             # 聊天记录目录
      │   ├── {message_id_1}.json  # 单条消息
      │   ├── {message_id_2}.json  # 单条消息
      │   └── ...
      └── code/             # 生成的代码目录
          ├── {code_id_1}.json     # 单个代码版本
          ├── {code_id_2}.json     # 单个代码版本
          └── latest.txt    # 最新代码版本的ID
   ```

2. **消息文件格式**：
   - 每条消息单独存储为一个JSON文件
   - 文件名使用消息UUID
   - 包含timestamp以便按时间顺序加载

3. **加载优化**：
   - 按需加载：初始只加载最近N条消息
   - 懒加载：滚动到较早消息时再加载历史记录
   - 缓存：保持内存中消息列表与持久化存储同步

## 与WorkspaceViewModel的集成

1. **发送消息流程**：
   ```
   用户输入 → WorkspaceViewModel.sendMessage() → 
   创建用户ChatMessage → 保存到本地 → 
   BFFService.sendMessage() → 接收AI响应 → 
   创建AI ChatMessage → 保存到本地 → 
   提取和保存HTML代码
   ```

2. **状态管理**：
   - 使用`@Published var isLoading: Bool`标记加载状态
   - 使用`@Published var error: Error?`处理错误
   - 使用`@Published var chatMessages: [ChatMessage]`存储消息列表

## 从API响应中提取代码

1. **解析Markdown格式**：
   - 查找markdown代码块（```html...```）
   - 提取HTML代码内容
   - 创建GeneratedCode对象存储

2. **代码版本控制**：
   - 每次生成的代码都创建新版本
   - 通过latest.txt标识最新版本
   - 可扩展为支持历史版本的查看/恢复功能

## 使用Settings连接API

1. **在请求前加载最新设置**：
   ```swift
   let settings = SettingsManager.shared.loadSettings()
   ```

2. **使用设置中的参数构建请求**：
   ```swift
   // 设置API端点
   var request = URLRequest(url: URL(string: settings.apiEndpoint + "/chat/completions")!)
   
   // 设置认证头
   request.addValue("Bearer \(settings.apiKey)", forHTTPHeaderField: "Authorization")
   
   // 设置选择的模型
   let requestBody = [
       "model": settings.selectedModel,
       "messages": [
           ["role": "user", "content": message]
       ]
   ]
   ```

## 错误处理策略

1. **用户友好的错误展示**：
   - API密钥错误："API密钥无效或已过期"
   - 网络问题："网络连接中断，请检查网络设置"
   - 服务器问题："服务器暂时不可用，请稍后再试"

2. **重试机制**：
   - 网络错误自动重试（最多3次）
   - 指数退避策略（等待时间逐渐增加）

## 离线支持

1. **查看历史消息**：
   - 即使离线也可查看已保存的消息
   - 清晰标识消息的本地/远程状态

2. **消息队列**：
   - 离线时将消息加入发送队列
   - 恢复连接后自动发送

## 安全考虑

1. **API密钥保护**：
   - 使用iOS Keychain存储API密钥而非UserDefaults
   - 避免在日志中打印API密钥

2. **数据加密**：
   - 考虑对存储的消息进行加密
   - 使用FileProtection确保文件系统级别的安全

## 性能优化

1. **流式响应**（可选增强功能）：
   - 支持OpenAI的流式API响应
   - 实时展示AI正在生成的内容

2. **消息历史优化**：
   - 对于长对话自动压缩/总结历史
   - 只发送相关上下文到API减少token使用

## 后续扩展思路

1. **多模型切换**：
   - 无缝支持设置中添加的自定义模型
   - 保存每个工作区首选的模型

2. **历史会话管理**：
   - 支持导出/导入聊天记录
   - 会话标记和分类

3. **混合会话**：
   - 支持在同一个会话中混合使用不同模型
   - 为每条消息标记使用的模型

这套方案充分利用了项目现有的MVVM架构，并与FileSystemWorkspaceDataManager无缝集成，确保了用户数据的持久化和工作区的独立性，同时保持了代码的模块化和可测试性。
