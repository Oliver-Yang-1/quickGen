import SwiftUI
import WebKit

struct PreviewView: View {
    @ObservedObject var viewModel: WorkspaceViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // 预览区域
            WebViewContainer(htmlString: viewModel.workspace.generatedHTML ?? "")
                .edgesIgnoringSafeArea(.all)
            
            // 底部工具栏
            HStack(spacing: 16) {
                // 复制代码按钮
                Button(action: {
                    viewModel.copyGeneratedCode()
                }) {
                    Label("复制代码", systemImage: "doc.on.doc")
                }
                .buttonStyle(ToolbarButtonStyle())
                
                // 导出按钮
                Button(action: {
                    viewModel.exportHTML()
                }) {
                    Label("导出", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(ToolbarButtonStyle())
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color(UIColor.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -5)
        }
    }
}

// WebView容器
struct WebViewContainer: UIViewRepresentable {
    let htmlString: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .white
        webView.isOpaque = false
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // 如果HTML为空，显示占位符
        let html = htmlString.isEmpty ? "<html><body><h2>尚未生成HTML内容</h2><p>请在聊天模式中描述您想要的网页，然后点击运行按钮。</p></body></html>" : htmlString
        
        uiView.loadHTMLString(html, baseURL: nil)
    }
}

// 工具栏按钮样式
struct ToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? .gray : .blue)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
                    .opacity(configuration.isPressed ? 0.7 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
} 