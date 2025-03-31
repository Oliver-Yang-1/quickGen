import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                // API设置部分
                Section(header: Text("API 设置").font(.headline)) {
                    // OpenAI API Key
                    VStack(alignment: .leading) {
                        Text("OpenAI API Key")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        SecureField("sk-...", text: $viewModel.openAIKey)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .textContentType(.password)
                            .onChange(of: viewModel.openAIKey) { _ in
                                viewModel.saveSettings()
                            }
                    }
                    .padding(.vertical, 4)
                    
                    // OpenAI Base URL
                    VStack(alignment: .leading) {
                        Text("OpenAI Base URL")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("https://api.openai.com/v1", text: $viewModel.openAIBaseURL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .keyboardType(.URL)
                            .onChange(of: viewModel.openAIBaseURL) { _ in
                                viewModel.saveSettings()
                            }
                    }
                    .padding(.vertical, 4)
                    
                    // OpenAI 模型选择
                    VStack(alignment: .leading) {
                        Text("OpenAI 模型")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $viewModel.selectedModelIndex) {
                            ForEach(0..<viewModel.availableModels.count, id: \.self) { index in
                                Text(viewModel.availableModels[index]).tag(index)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: viewModel.selectedModelIndex) { _ in
                            viewModel.updateSelectedModel()
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // 外观设置部分
                Section(header: Text("外观").font(.headline)) {
                    Picker("主题", selection: $viewModel.appearance) {
                        Text("跟随系统").tag(AppAppearance.system)
                        Text("浅色模式").tag(AppAppearance.light)
                        Text("深色模式").tag(AppAppearance.dark)
                    }
                    .onChange(of: viewModel.appearance) { _ in
                        viewModel.saveSettings()
                    }
                }
                
                // 关于信息
                Section(header: Text("关于").font(.headline)) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        Text("隐私政策")
                    }
                    
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        Text("使用条款")
                    }
                }
                
                // 重置设置按钮
                Section {
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        Text("重置所有设置")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarItems(
                trailing: Button("完成") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .alert(isPresented: $showingResetAlert) {
                Alert(
                    title: Text("重置设置"),
                    message: Text("确定要将所有设置重置为默认值吗？此操作无法撤销。"),
                    primaryButton: .destructive(Text("重置")) {
                        viewModel.resetToDefaults()
                    },
                    secondaryButton: .cancel(Text("取消"))
                )
            }
        }
        .preferredColorScheme(viewModel.appearance.colorScheme)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
} 