import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: SidebarViewModel
    @State private var isSearchActive = false
    @State private var isShowingSettings = false
    
    // 触发创建新工作区的回调
    var onCreateNewWorkspace: () -> Void
    // 选择工作区的回调
    var onSelectWorkspace: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜索工作区", text: $viewModel.searchText, onEditingChanged: { isEditing in
                    isSearchActive = isEditing
                })
                .foregroundColor(.primary)
                
                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.searchText = ""
                        isSearchActive = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            // 主要内容区域 - 使用List
            List {
                // 工作区部分
                Section(header: 
                    Text("工作区")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top, 5)
                ) {
                    // 工作区列表
                    if viewModel.filteredWorkspaces.isEmpty {
                        Text("没有工作区")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(viewModel.filteredWorkspaces, id: \.self) { workspace in
                            Button(action: {
                                onSelectWorkspace(workspace)
                            }) {
                                HStack {
                                    Image(systemName: "doc.text")
                                        .foregroundColor(.gray)
                                    Text(workspace)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            
            // 底部工具栏
            HStack {
                Button(action: {
                    onCreateNewWorkspace()
                }) {
                    Image(systemName: "plus")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                Button(action: {
                    isShowingSettings = true
                }) {
                    Image(systemName: "gear")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            .background(Color(UIColor.systemBackground))
        }
        .frame(width: 250)
        .background(Color(UIColor.systemBackground))
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
    }
}

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView(
            viewModel: SidebarViewModel(),
            onCreateNewWorkspace: {},
            onSelectWorkspace: { _ in }
        )
    }
} 