import SwiftUI

struct WorkspaceContentView: View {

    @StateObject private var viewModel: WorkspaceViewModel
    @Binding var isSidebarVisible: Bool
    @State private var completionProgress: Double = 0.0
    @State private var isCompleted: Bool = false
    @State private var isSubmitted: Bool = false  // 新增提交状态
    @State private var showingStatusAlert = false
    @State private var statusMessage = ""

    init(workspace: Workspace, isSidebarVisible: Binding<Bool>) {
        self._viewModel = StateObject(wrappedValue: WorkspaceViewModel(workspace: workspace))
        self._isSidebarVisible = isSidebarVisible
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 顶部工具栏
                HStack {
                    // 侧边栏按钮
                    Button(action: {
                        withAnimation(.spring()) {
                            isSidebarVisible.toggle()
                        }
                    }) {
                        Image(systemName: "line.horizontal.3")
                            .font(.title3)
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    // 工作区名称
                    Text(viewModel.workspace.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    // 提交按钮
                    Button(action: {
                        if(viewModel.isLoading){
                            return
                        }
                        
                        // 调用更新聊天记录的函数
                        Task {
                            await updateChatNearlyTen()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: isSubmitted ? "checkmark.circle.fill" : "arrow.up.circle")
                                .font(.title3)
                            Text(isSubmitted ? "已提交" : "提交任务")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(isSubmitted ? .green : .blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isSubmitted ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                        )
                    }
                    .disabled(viewModel.isLoading || isSubmitted)
                    
                    // 预览按钮
                    Button(action:{
                        // 获取任务状态
                        Task {
                            await getChatTaskStatus()
                        }
                    }) {
                        Image(systemName: "play.fill")
                            .font(.title3)
                            .foregroundColor(.black)
                    }
                    .disabled(viewModel.isLoading)
                    .alert("任务状态", isPresented: $showingStatusAlert) {
                        Button("确定", role: .cancel) { }
                    } message: {
                        Text(statusMessage)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
                
                Divider()
                
                // 默认显示聊天视图
                ChatView(viewModel: viewModel)
            }
            .navigationBarHidden(true)
        }
    }
    
    func updateChatNearlyTen() async {
        // Get the last 10 messages or all if less than 10
        let messagesToSend = Array(viewModel.chatMessages.suffix(10))
        
        // Convert messages to dictionary format
        let messageDicts = messagesToSend.map { message in
            [
                "id": message.id.uuidString,
                "workspaceId": message.workspaceId.uuidString,
                "sender": message.sender.rawValue,
                "content": message.content,
                "timestamp": message.timestamp.timeIntervalSince1970
            ]
        }
        
        let settings = SettingsManager.shared.loadSettings()
        let url = "\(settings.webApi)/projects/\(settings.userName)/\(viewModel.workspace.name)"
        print("chatView: 上传聊天记录: \(url)")
        guard let requestURL = URL(string: url) else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: ["prompt": "创建一个简单的倒计时网页，具有现代设计风格和平滑的动画效果"])
            //数据多会卡
//            request.httpBody = try JSONSerialization.data(withJSONObject: ["prompt": messageDicts])
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                return
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Response data: \(jsonString)")
                    // 更新提交状态
                    DispatchQueue.main.async {
                        isSubmitted = true
                    }
                }
            } else {
                print("Request failed with status code: \(httpResponse.statusCode)")
                if let errorString = String(data: data, encoding: .utf8) {
                    print("Error response: \(errorString)")
                }
            }
        } catch {
            print("Error making request: \(error.localizedDescription)")
        }
    }
    
    func getChatTaskStatus() async {
        let settings = SettingsManager.shared.loadSettings()
        
        let url = "\(settings.webApi)/projects/\(settings.userName)/\(viewModel.workspace.name)/status"
        print("chatView: 查询任务状态: \(url)")
        guard let requestURL = URL(string: url) else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "Get"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                return
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                if let jsonString = String(data: data, encoding: .utf8),
                   let jsonData = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let status = json["status"] as? String {
                    
                    DispatchQueue.main.async {
                        if status == "UPDATING" || status == "CREATING" || status == "NOT_FOUND" {
                            statusMessage = "任务正在\(status == "UPDATING" ? "更新" : "创建")中，请稍后再试"
                            showingStatusAlert = true
                        } else {
                            // 打开浏览器
                            let web_url = "\(settings.webApi)/view/\(settings.userName)/\(viewModel.workspace.name)"
                            print("chatView: 跳转浏览器网址: \(web_url)")
                            if let url = URL(string: web_url) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                }
            } else {
                print("Request failed with status code: \(httpResponse.statusCode)")
                if let errorString = String(data: data, encoding: .utf8) {
                    print("Error response: \(errorString)")
                }
            }
        } catch {
            print("Error making request: \(error.localizedDescription)")
        }
    }
    
}

struct WorkspaceContentView_Previews: PreviewProvider {
    static var previews: some View {
        let workspace = Workspace(name: "示例工作区")
        WorkspaceContentView(workspace: workspace, isSidebarVisible: .constant(false))
    }
} 
