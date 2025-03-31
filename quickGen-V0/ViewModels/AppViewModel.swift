import Foundation
import Combine

class AppViewModel: ObservableObject {
    // 工作区列表
    @Published var workspaces: [Workspace] = []
    // 当前选中的工作区
    @Published var selectedWorkspace: Workspace?
    // 是否显示欢迎界面
    @Published var showWelcomeView: Bool = true
    
    // 工作区数据管理器
    private let workspaceDataManager: WorkspaceDataManager
    
    init(workspaceDataManager: WorkspaceDataManager = FileSystemWorkspaceDataManager.shared) {
        self.workspaceDataManager = workspaceDataManager
        loadWorkspaces()
    }
    
    // 加载工作区列表
    func loadWorkspaces() {
        // 使用WorkspaceDataManager加载工作区
        workspaces = workspaceDataManager.fetchWorkspaces()
        
        // 如果没有工作区，则显示欢迎界面
        if workspaces.isEmpty {
            showWelcomeView = true
            selectedWorkspace = nil
        }
    }
    
    // 创建新工作区 - 统一的工作区创建入口
    func createWorkspace(name: String, autoSelect: Bool = true) -> Workspace {
        // 使用WorkspaceDataManager创建工作区
        let newWorkspace = workspaceDataManager.createWorkspace(name: name)
        
        // 将新工作区添加到列表中
        workspaces.insert(newWorkspace, at: 0)
        
        // 如果需要自动选择新创建的工作区
        if autoSelect {
            selectWorkspace(newWorkspace)
        }
        
        return newWorkspace
    }
    
    // 选择工作区
    func selectWorkspace(_ workspace: Workspace) {
        selectedWorkspace = workspace
        showWelcomeView = false
    }
    
    // 返回欢迎界面
    func goToWelcomeView() {
        selectedWorkspace = nil
        showWelcomeView = true
    }
    
    // 删除工作区
    func deleteWorkspace(_ workspace: Workspace) -> Bool {
        let success = workspaceDataManager.deleteWorkspace(workspace)
        if success {
            // 从内存中移除工作区
            workspaces.removeAll { $0.id == workspace.id }
            
            // 如果删除的是当前选中的工作区，返回欢迎界面
            if selectedWorkspace?.id == workspace.id {
                goToWelcomeView()
            }
        }
        return success
    }
    
    // 重命名工作区
    func renameWorkspace(_ workspace: Workspace, to newName: String) -> Bool {
        let success = workspaceDataManager.renameWorkspace(workspace, to: newName)
        if success {
            // 更新内存中的工作区
            if let index = workspaces.firstIndex(where: { $0.id == workspace.id }) {
                var updatedWorkspace = workspace
                updatedWorkspace.name = newName
                updatedWorkspace.lastModifiedDate = Date()
                workspaces[index] = updatedWorkspace
                
                // 如果重命名的是当前选中的工作区，更新选中的工作区
                if selectedWorkspace?.id == workspace.id {
                    selectedWorkspace = updatedWorkspace
                }
            }
        }
        return success
    }
} 