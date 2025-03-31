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
                        
                        HStack {
                            if viewModel.isApiKeyVisible {
                                TextField("sk-...", text: $viewModel.apiKey)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .onChange(of: viewModel.apiKey) { _ in
                                        viewModel.saveSettings()
                                    }
                            } else {
                                SecureField("sk-...", text: $viewModel.apiKey)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .onChange(of: viewModel.apiKey) { _ in
                                        viewModel.saveSettings()
                                    }
                            }
                            
                            Button(action: {
                                viewModel.toggleApiKeyVisibility()
                            }) {
                                Image(systemName: viewModel.isApiKeyVisible ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    // API端点
                    VStack(alignment: .leading) {
                        Text("OpenAI API 端点")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("https://api.openai.com/v1", text: $viewModel.apiEndpoint)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .keyboardType(.URL)
                            .onChange(of: viewModel.apiEndpoint) { _ in
                                viewModel.saveSettings()
                            }
                    }
                    .padding(.vertical, 4)
                    
                    // 模型选择
                    VStack(alignment: .leading) {
                        Text("AI 模型")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Picker("选择模型", selection: $viewModel.selectedModel) {
                                ForEach(viewModel.availableModels, id: \.self) { model in
                                    Text(model).tag(model)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: viewModel.selectedModel) { _ in
                                viewModel.updateSelectedModel()
                            }
                            
                            Button(action: {
                                viewModel.showingAddModelAlert = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title3)
                            }
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
            .alert("添加自定义模型", isPresented: $viewModel.showingAddModelAlert) {
                TextField("模型名称", text: $viewModel.newModelName)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                Button("取消", role: .cancel) {
                    viewModel.newModelName = ""
                }
                
                Button("添加") {
                    viewModel.addCustomModel()
                }
            } message: {
                Text("请输入想要添加的AI模型名称")
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