# AI Chat H5 Generator (iOS App)

## 描述 (Description)

本项目是一个iOS应用程序，旨在让用户通过与AI的聊天交互来快速生成简单的H5网页。用户可以在聊天窗口中描述他们想要的网页内容和样式，AI将根据描述生成HTML代码，用户可以运行（预览）生成的代码。

## 项目结构 (Project Structure)

```
quickGen-V0/
├── Models/                      # 数据模型
│   ├── Workspace.swift          # 工作区数据模型
│   ├── ChatMessage.swift        # 聊天消息数据模型
│   └── GeneratedCode.swift      # 生成的代码数据模型
├── Services/                    # 服务层
│   └── WorkspaceDataManager.swift # 工作区数据管理服务
├── ViewModels/                  # 视图模型层
│   ├── AppViewModel.swift       # 应用程序视图模型
│   ├── WorkspaceViewModel.swift # 工作区视图模型
│   ├── SidebarViewModel.swift   # 侧边栏视图模型
│   ├── WelcomeViewModel.swift   # 欢迎界面视图模型
│   └── SettingsViewModel.swift  # 设置视图模型
├── Views/                       # 视图层
│   ├── MainView.swift           # 主视图
│   ├── WelcomeView.swift        # 欢迎界面
│   ├── WorkspaceContentView.swift # 工作区内容视图
│   ├── SidebarView.swift        # 侧边栏视图
│   ├── ChatView.swift           # 聊天界面视图
│   ├── PreviewView.swift        # 预览界面视图
│   ├── NewWorkspaceModalView.swift # 新建工作区模态框
│   └── SettingsView.swift       # 设置界面视图
├── quickGen_V0App.swift         # 应用程序入口点
├── Assets.xcassets/             # 应用资源
└── Preview Content/             # 预览资源
```

## 文件功能说明

### 数据模型 (Models)

* **Workspace.swift**
  * 定义工作区数据结构，包含ID、名称、创建日期、修改日期、是否收藏和生成的HTML代码等属性
  * 提供辅助方法，如获取文件夹名和判断相等性

* **ChatMessage.swift**
  * 定义聊天消息数据结构，包含ID、所属工作区ID、发送者、内容、时间戳和是否为错误消息等属性
  * 包含MessageSender枚举，定义消息发送者类型（用户或AI）

* **GeneratedCode.swift**
  * 定义生成的代码数据结构，包含ID、所属工作区ID、HTML内容和时间戳等属性

### 服务层 (Services)

* **WorkspaceDataManager.swift**
  * 定义WorkspaceDataManager协议，声明工作区数据管理的方法
  * 实现FileSystemWorkspaceDataManager类，使用文件系统存储工作区数据
  * 提供工作区、聊天消息和生成代码的CRUD操作
  * 管理文件系统目录结构，确保数据持久化

### 视图模型层 (ViewModels)

* **AppViewModel.swift**
  * 管理应用程序全局状态，包括工作区列表、当前选中的工作区和是否显示欢迎界面
  * 提供加载、创建、选择和管理工作区的方法
  * 作为工作区数据与视图之间的桥梁

* **WorkspaceViewModel.swift**
  * 管理单个工作区的状态和交互逻辑
  * 处理聊天消息的发送和接收、HTML代码的生成和预览
  * 切换聊天模式和预览模式
  * 管理工作区的内容修改和保存

* **SidebarViewModel.swift**
  * 管理侧边栏的工作区列表和搜索功能
  * 提供工作区加载、筛选和获取方法
  * 支持按名称搜索工作区

* **WelcomeViewModel.swift**
  * 管理欢迎界面的状态和交互逻辑
  * 处理新建工作区的模态框显示和工作区创建
  * 管理最近工作区列表

* **SettingsViewModel.swift**
  * 管理应用程序设置
  * 处理API设置、应用外观和其他配置选项
  * 提供设置的加载、保存和重置功能

### 视图层 (Views)

* **MainView.swift**
  * 应用程序的主容器视图
  * 根据当前状态显示欢迎界面或工作区内容
  * 管理侧边栏的显示和隐藏
  * 协调各个子视图之间的交互

* **WelcomeView.swift**
  * 显示应用程序的欢迎界面
  * 提供新建工作区和打开最近工作区的入口
  * 包含文档、社区论坛和发布说明的链接
  * 包含侧边栏的集成

* **WorkspaceContentView.swift**
  * 显示工作区的内容
  * 根据当前模式切换显示ChatView或PreviewView
  * 包含工作区顶部工具栏

* **SidebarView.swift**
  * 显示工作区列表和搜索栏
  * 提供工作区创建和选择功能
  * 底部包含新建工作区和设置按钮

* **ChatView.swift**
  * 显示聊天界面
  * 提供消息输入框和发送按钮
  * 展示用户和AI的消息历史
  * 支持滚动查看历史消息

* **PreviewView.swift**
  * 使用WKWebView显示生成的HTML代码预览
  * 提供刷新和返回聊天界面的功能

* **NewWorkspaceModalView.swift**
  * 新建工作区的模态框
  * 提供工作区名称输入和创建功能

* **SettingsView.swift**
  * 显示应用程序设置界面
  * 提供API设置、应用外观和其他配置选项的调整

## 架构说明

本项目采用MVVM (Model-View-ViewModel) 架构模式，实现了清晰的关注点分离：

1. **模型层 (Model)** - 定义数据结构和业务逻辑
2. **视图层 (View)** - 使用SwiftUI实现的用户界面
3. **视图模型层 (ViewModel)** - 连接模型和视图，处理业务逻辑
4. **服务层 (Service)** - 处理数据持久化和外部系统交互

数据流遵循单向流动原则：视图通过视图模型读取和更新数据，视图模型通过服务层持久化数据。使用SwiftUI的响应式特性，当数据变化时自动更新UI。

## 核心功能 (Key Features)

* **工作区管理:**
  * 创建、选择和管理多个工作区
  * 工作区数据持久化存储

* **聊天界面:**
  * 与AI进行自然语言交互
  * 支持发送消息和生成网页代码
  * 显示消息历史和聊天上下文

* **代码预览:**
  * 实时预览生成的HTML代码
  * 使用WKWebView渲染HTML内容

* **设置选项:**
  * 配置应用外观和API设置
  * 自定义用户体验

## 技术栈 (Tech Stack)

* **语言:** Swift
* **UI框架:** SwiftUI (用于构建声明式、响应式的用户界面)
* **网络请求:** URLSession (用于与BFF或AI API通信)
* **状态管理:** SwiftUI内置机制 (`@State`, `@StateObject`, `@ObservedObject`, `@Published`)
* **持久化:** FileManager (用于文件系统存储)
* **Web渲染:** WKWebView (用于HTML预览)

