import SwiftUI

struct WelcomeView: View {
    @StateObject private var viewModel: WelcomeViewModel
    @StateObject private var sidebarViewModel = SidebarViewModel()
    @State private var isSidebarVisible = false
    @State private var isShowingSettings = false
    
    var onCreateNewWorkspace: () -> Void
    var onShowSettings: () -> Void
    
    init(appViewModel: AppViewModel, onCreateNewWorkspace: @escaping () -> Void, onShowSettings: @escaping () -> Void) {
        self._viewModel = StateObject(wrappedValue: WelcomeViewModel(appViewModel: appViewModel))
        self.onCreateNewWorkspace = onCreateNewWorkspace
        self.onShowSettings = onShowSettings
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 主内容
                VStack {
                    // 顶部工具栏
                    HStack {
                        Button(action: {
                            withAnimation(.spring()) {
                                isSidebarVisible.toggle()
                            }
                        }) {
                            Image(systemName: "line.horizontal.3")
                                .font(.title2)
                                .foregroundColor(.primary)
                                .padding(.horizontal)
                        }
                        
                        Spacer()
                        
                        Text("QuickGen")
                            .font(.headline)
                            .bold()
                        
                        Spacer()
                        
                        Button(action: onShowSettings) {
                            Image(systemName: "gear")
                                .font(.title2)
                                .foregroundColor(.primary)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                    .background(Color(UIColor.systemBackground))
                    
                    // 主要内容区域
                    VStack(spacing: 20) {
                        Spacer()
                        
                        // 应用Logo（可自定义）
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 64))
                            .foregroundColor(.blue)
                        
                        Text("欢迎使用 QuickGen")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("快速生成H5网页的AI助手")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // 主要操作按钮
                        VStack(spacing: 16) {
                            // 新建工作区按钮
                            Button(action: onCreateNewWorkspace) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("新建工作区...")
                                }
                                .frame(maxWidth: 300)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            
                            // 打开最近工作区按钮
                            Button(action: {
                                viewModel.triggerOpenRecentWorkspace()
                            }) {
                                HStack {
                                    Image(systemName: "folder")
                                    Text("打开最近工作区...")
                                }
                                .frame(maxWidth: 300)
                                .padding()
                                .background(Color(UIColor.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                            }
                        }
                        .padding(.vertical)
                        
                        // 次要操作链接
                        VStack(spacing: 12) {
                            Button("使用文档") {
                                viewModel.openDocumentation()
                            }
                            .foregroundColor(.blue)
                            
                            Button("社区论坛") {
                                viewModel.openCommunityForum()
                            }
                            .foregroundColor(.blue)
                            
                            Button("发布说明") {
                                viewModel.openReleaseNotes()
                            }
                            .foregroundColor(.blue)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
                .navigationBarHidden(true)
                .sheet(isPresented: $viewModel.isShowingNewWorkspaceModal) {
                    newWorkspaceModal
                }
                .sheet(isPresented: $viewModel.isShowingRecentWorkspaces) {
                    recentWorkspacesView
                }
                .sheet(isPresented: $isShowingSettings) {
                    SettingsView()
                }
                
                // 侧边栏和遮罩
                ZStack {
                    // 当侧边栏可见时，添加半透明遮罩
                    if isSidebarVisible {
                        Color.black.opacity(0.3)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    isSidebarVisible = false
                                }
                            }
                    }
                    
                    // 侧边栏
                    HStack(spacing: 0) {
                        if isSidebarVisible {
                            SidebarView(
                                viewModel: sidebarViewModel,
                                onCreateNewWorkspace: {
                                    isSidebarVisible = false
                                    viewModel.triggerNewWorkspaceCreation()
                                },
                                onSelectWorkspace: { workspaceName in
                                    // 选择工作区的逻辑
                                    if let workspace = sidebarViewModel.getWorkspace(byName: workspaceName) {
                                        viewModel.appViewModel.selectWorkspace(workspace)
                                        isSidebarVisible = false
                                    } else {
                                        print("错误：无法找到名为 \(workspaceName) 的工作区")
                                        // 可以在这里添加用户提示或其他错误处理
                                    }
                                }
                            )
                            .transition(.move(edge: .leading))
                        }
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    // 新建工作区模态框
    var newWorkspaceModal: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("名称:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Untitled", text: $viewModel.newWorkspaceName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 20)
                
                Spacer()
            }
            .padding()
            .navigationTitle("新建工作区")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("取消") {
                    viewModel.isShowingNewWorkspaceModal = false
                },
                trailing: Button("创建") {
                    viewModel.createNewWorkspace()
                }
                .disabled(viewModel.newWorkspaceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .bold()
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // 最近工作区视图
    var recentWorkspacesView: some View {
        NavigationView {
            List(viewModel.recentWorkspaces, id: \.self) { workspace in
                Button(action: {
                    // 打开选中的工作区
                    viewModel.isShowingRecentWorkspaces = false
                }) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text(workspace)
                    }
                }
            }
            .navigationTitle("最近的工作区")
            .navigationBarItems(trailing: Button("关闭") {
                viewModel.isShowingRecentWorkspaces = false
            })
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(
            appViewModel: AppViewModel(),
            onCreateNewWorkspace: {},
            onShowSettings: {}
        )
    }
} 