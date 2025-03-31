import SwiftUI

struct WorkspaceContentView: View {
    @StateObject var viewModel: WorkspaceViewModel
    @Binding var isSidebarVisible: Bool
    
    var body: some View {
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
                
                // 播放/预览按钮（将预览和运行功能合并为一个播放按钮）
                Button(action: {
                    if viewModel.isPreviewMode {
                        // 如果已经在预览模式，点击运行生成
                        viewModel.runGeneration()
                    } else {
                        // 如果在聊天模式，切换到预览模式
                        viewModel.togglePreviewMode()
                    }
                }) {
                    Image(systemName: "play.fill")
                        .font(.title3)
                        .foregroundColor(.black)
                }
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
            
            Divider()
            
            // 内容区域（聊天或预览）
            if viewModel.isPreviewMode {
                PreviewView(viewModel: viewModel)
            } else {
                ChatView(viewModel: viewModel)
            }
        }
        .navigationBarHidden(true)
    }
}

struct WorkspaceContentView_Previews: PreviewProvider {
    static var previews: some View {
        let workspace = Workspace(name: "示例工作区")
        WorkspaceContentView(viewModel: WorkspaceViewModel(workspace: workspace), isSidebarVisible: .constant(false))
    }
} 