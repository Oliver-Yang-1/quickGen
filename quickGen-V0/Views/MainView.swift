import SwiftUI

struct MainView: View {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var sidebarViewModel = SidebarViewModel()
    @State private var isSidebarVisible = false
    @State private var isShowingSettings = false
    @State private var isShowingNewWorkspaceModal = false
    @State private var newWorkspaceName = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // 主内容区域
                Group {
                    if appViewModel.showWelcomeView {
                        // 欢迎界面
                        WelcomeView(
                            appViewModel: appViewModel,
                            onCreateNewWorkspace: { isShowingNewWorkspaceModal = true },
                            onShowSettings: { isShowingSettings = true }
                        )
                    } else if let workspace = appViewModel.selectedWorkspace {
                        // 工作区内容
                        WorkspaceContentView(
                            viewModel: WorkspaceViewModel(workspace: workspace),
                            isSidebarVisible: $isSidebarVisible
                        )
                    }
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
                                    isShowingNewWorkspaceModal = true
                                },
                                onSelectWorkspace: { workspaceName in
                                    if let workspace = sidebarViewModel.getWorkspace(byName: workspaceName) {
                                        appViewModel.selectWorkspace(workspace)
                                        isSidebarVisible = false
                                    }
                                }
                            )
                            .transition(.move(edge: .leading))
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $isShowingNewWorkspaceModal) {
                NewWorkspaceModalView(
                    isShowing: $isShowingNewWorkspaceModal,
                    workspaceName: $newWorkspaceName,
                    onCancel: {
                        isShowingNewWorkspaceModal = false
                        newWorkspaceName = ""
                    },
                    onCreate: {
                        createNewWorkspace()
                    }
                )
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // 创建新工作区
    private func createNewWorkspace() {
        let name = newWorkspaceName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        
        // 创建工作区并自动选择
        let workspace = appViewModel.createWorkspace(name: name)
        
        // 更新侧边栏中的工作区列表
        sidebarViewModel.refreshWorkspaces()
        
        // 重置状态
        isShowingNewWorkspaceModal = false
        newWorkspaceName = ""
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
} 