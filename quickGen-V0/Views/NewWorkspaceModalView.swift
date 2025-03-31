import SwiftUI

struct NewWorkspaceModalView: View {
    @Binding var isShowing: Bool
    @Binding var workspaceName: String
    var onCancel: () -> Void
    var onCreate: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("名称:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Untitled", text: $workspaceName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 20)
                
                Spacer()
            }
            .padding()
            .navigationTitle("新建工作区")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("取消") {
                    onCancel()
                },
                trailing: Button("创建") {
                    onCreate()
                }
                .disabled(workspaceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .bold()
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct NewWorkspaceModalView_Previews: PreviewProvider {
    static var previews: some View {
        NewWorkspaceModalView(
            isShowing: .constant(true),
            workspaceName: .constant("My Workspace"),
            onCancel: {},
            onCreate: {}
        )
    }
} 