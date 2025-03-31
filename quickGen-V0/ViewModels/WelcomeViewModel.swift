import Foundation
import Combine

class WelcomeViewModel: ObservableObject {
    // 最近的工作区列表
    @Published var recentWorkspaces: [String] = []
    
    // 临时变量，用于创建新工作区的名称
    @Published var newWorkspaceName: String = ""
    // 控制新工作区创建模态框的显示
    @Published var isShowingNewWorkspaceModal: Bool = false
    // 控制打开最近工作区列表的显示
    @Published var isShowingRecentWorkspaces: Bool = false
    
    // 引用AppViewModel
    let appViewModel: AppViewModel
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        // 模拟加载最近的工作区
        self.recentWorkspaces = ["示例工作区", "我的登陆页面", "产品介绍页"]
    }
    
    // 触发新工作区创建模态框
    func triggerNewWorkspaceCreation() {
        newWorkspaceName = ""
        isShowingNewWorkspaceModal = true
    }
    
    // 触发打开最近工作区
    func triggerOpenRecentWorkspace() {
        isShowingRecentWorkspaces = true
    }
    
    // 创建新工作区
    func createNewWorkspace() {
        let name = newWorkspaceName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        
        // 使用AppViewModel创建工作区
        let workspace = appViewModel.createWorkspace(name: name)
        
        // 添加到最近工作区列表
        recentWorkspaces.insert(workspace.name, at: 0)
        
        // 关闭模态框
        isShowingNewWorkspaceModal = false
        newWorkspaceName = ""
    }
    
    // 打开文档
    func openDocumentation() {
        // 打开文档的逻辑（未实现）
        print("打开文档")
    }
    
    // 打开社区论坛
    func openCommunityForum() {
        // 打开社区论坛的逻辑（未实现）
        print("打开社区论坛")
    }
    
    // 打开发布说明
    func openReleaseNotes() {
        // 打开发布说明的逻辑（未实现）
        print("打开发布说明")
    }
} 