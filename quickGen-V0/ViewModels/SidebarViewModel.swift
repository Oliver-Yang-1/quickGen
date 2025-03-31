import Foundation
import Combine

class SidebarViewModel: ObservableObject {
    // 工作区列表
    @Published var workspaces: [String] = []
    @Published var favoriteWorkspaces: [String] = []
    @Published var exampleWorkspaces: [String] = ["基础HTML页面", "响应式布局", "表单示例"]
    @Published var searchText: String = ""
    
    // 工作区数据管理器
    private let workspaceDataManager: WorkspaceDataManager
    // 工作区完整对象列表
    private var fullWorkspaces: [Workspace] = []
    
    // 筛选后的工作区列表
    var filteredWorkspaces: [String] {
        if searchText.isEmpty {
            return workspaces
        } else {
            return workspaces.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    init(workspaceDataManager: WorkspaceDataManager = FileSystemWorkspaceDataManager.shared) {
        self.workspaceDataManager = workspaceDataManager
        loadWorkspaces()
    }
    
    // 加载工作区
    func loadWorkspaces() {
        // 使用WorkspaceDataManager加载工作区列表
        fullWorkspaces = workspaceDataManager.fetchWorkspaces()
        workspaces = fullWorkspaces.map { $0.name }
    }
    
    // 更新工作区列表
    func refreshWorkspaces() {
        loadWorkspaces()
    }
    
    // 根据名称获取工作区
    func getWorkspace(byName name: String) -> Workspace? {
        return fullWorkspaces.first { $0.name == name }
    }
    
    // 获取所有工作区
    func getAllWorkspaces() -> [Workspace] {
        return fullWorkspaces
    }
    
    // 添加到收藏夹
    func addToFavorites(workspace: String) {
        if !favoriteWorkspaces.contains(workspace) {
            favoriteWorkspaces.append(workspace)
        }
    }
    
    // 从收藏夹移除
    func removeFromFavorites(workspace: String) {
        favoriteWorkspaces.removeAll { $0 == workspace }
    }
    
    // 打开垃圾箱
    func openTrash() {
        // 垃圾箱功能实现（未完成）
        print("打开垃圾箱")
    }
} 