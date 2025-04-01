import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: WorkspaceViewModel
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 聊天历史
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.chatMessages) { message in
                            MessageBubble(
                                message: message,
                                isStreaming: viewModel.streamingMessageId == message.id
                            )
                            .id(message.id)
                        }
                        
                        if viewModel.isLoading {
                            LoadingIndicator()
                                .padding()
                                .id("loading")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                }
                .onChange(of: viewModel.chatMessages.count) { _ in
                    scrollToBottom(proxy: scrollProxy)
                }
                .onChange(of: viewModel.isLoading) { _ in
                    scrollToBottom(proxy: scrollProxy)
                }
                // 添加对流式消息变化的监听
                .onChange(of: viewModel.chatMessages.last?.content) { _ in
                    scrollToBottom(proxy: scrollProxy)
                }
                .onAppear {
                    scrollToBottom(proxy: scrollProxy)
                }
            }
            
            // 错误信息
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }
            
            // 底部输入区域
            ZStack(alignment: .bottom) {
                Color.white
                    .frame(height: 60)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -5)
                
                HStack(spacing: 12) {
                    TextField("描述您想要的网页...", text: $viewModel.userInput)
                        .padding(10)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(20)
                        .focused($isInputFocused)
                        .submitLabel(.send)
                        .onSubmit {
                            viewModel.sendMessage()
                        }
                    
                    Button(action: {
                        viewModel.sendMessage()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(viewModel.userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = viewModel.chatMessages.last {
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        } else if viewModel.isLoading {
            withAnimation {
                proxy.scrollTo("loading", anchor: .bottom)
            }
        }
    }
}

// 消息气泡组件
struct MessageBubble: View {
    let message: ChatMessage
    let isStreaming: Bool
    @State private var isShowingCode = false
    
    var body: some View {
        HStack(alignment: .top) {
            // 用户消息靠右，AI消息靠左
            if message.sender == .user {
                Spacer()
            }
            
            VStack(alignment: message.sender == .user ? .trailing : .leading, spacing: 4) {
                // 发送者标识
                HStack {
                    if message.sender == .user {
                        Spacer()
                        Text("用户")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("AI")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                
                // 消息内容
                if message.isError {
                    // 错误消息
                    Text(message.content)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                } else if let codeContent = extractCodeBlock(from: message.content), message.sender == .ai {
                    // AI回复包含代码
                    VStack(alignment: .leading, spacing: 8) {
                        // 文本部分
                        Text(extractTextBeforeCode(from: message.content))
                            .padding(.horizontal)
                            .padding(.top)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // 代码控制按钮
                        VStack(alignment: .leading, spacing: 0) {
                            Button(action: {
                                isShowingCode.toggle()
                            }) {
                                HStack {
                                    Text("显示HTML代码")
                                        .font(.system(size: 14, weight: .medium))
                                    
                                    Spacer()
                                    
                                    Image(systemName: isShowingCode ? "chevron.up" : "chevron.down")
                                }
                                .foregroundColor(.blue)
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // 折叠的代码显示区域
                            if isShowingCode {
                                ScrollView {
                                    Text(codeContent)
                                        .font(.system(.body, design: .monospaced))
                                        .padding()
                                }
                                .frame(maxHeight: 300)
                                .background(Color(UIColor.systemGray6))
                            }
                        }
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                    }
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.8, alignment: .leading)
                    .background(Color(UIColor.systemGray5))
                    .cornerRadius(12)
                } else {
                    // 普通消息
                    VStack(alignment: .leading) {
                        Text(message.content)
                            .padding()
                            .background(message.sender == .user ? Color.blue.opacity(0.2) : Color(UIColor.systemGray5))
                            .cornerRadius(12)
                        
                        // 如果是流式响应中的消息，显示打字指示器
                        if isStreaming && message.sender == .ai {
                            TypingIndicator()
                                .padding(.leading, 8)
                        }
                    }
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.8)
            
            if message.sender == .ai {
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
    
    // 从消息中提取代码块
    private func extractCodeBlock(from text: String) -> String? {
        guard text.contains("```html"), text.contains("```") else {
            return nil
        }
        
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
    
    // 提取代码块前的文本
    private func extractTextBeforeCode(from text: String) -> String {
        guard let range = text.range(of: "```html") else {
            return text
        }
        
        return String(text[..<range.lowerBound])
    }
}

// 打字指示器组件
struct TypingIndicator: View {
    @State private var animationState = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 6, height: 6)
                    .scaleEffect(animationState ? 1.0 : 0.5)
                    .animation(
                        Animation.easeInOut(duration: 0.3)
                            .repeatForever()
                            .delay(Double(i) * 0.15),
                        value: animationState
                    )
            }
        }
        .padding(6)
        .onAppear {
            animationState = true
        }
    }
}

// 加载指示器
struct LoadingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) / 6),
                        value: isAnimating
                    )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
        .onAppear {
            isAnimating = true
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        let workspace = Workspace(name: "测试工作区")
        return ChatView(viewModel: WorkspaceViewModel(workspace: workspace))
    }
} 