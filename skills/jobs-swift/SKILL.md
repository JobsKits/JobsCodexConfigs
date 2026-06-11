---
name: jobs-swift
description: 当任务涉及 Swift、Swift 文件组织、懒加载、SnapKit、导航栏配置、控制器组织或 Swift return self 收口时使用。
---

# Jobs Swift 写作规范

> 本技能由 `💻JobsCodexConfigs/AGENTS.md` 拆分而来，保留原有 Jobs 工作规范。只有当前任务命中本技能描述时才加载本文件，避免把所有细则长期塞进全局上下文。

## 七、[**Swift**](https://www.swift.org/) 写作规范 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 7.1、文件基座与依赖导入

- [**Swift**](https://www.swift.org/) 文件最顶层优先写系统基础框架判断，再引入 Jobs 本地 Pod 化框架；不要把 `UIKit` / `AppKit` 分散到业务代码中。

  ```swift
  #if os(OSX)
  import AppKit
  #elseif os(iOS) || os(tvOS)
  import UIKit
  #endif

  import JobsByUIKit
  import JobsSwiftBlock

  #if canImport(SnapKit)
  import SnapKit
  #endif

  final class DemoVC: BaseVC {
  }
  ```

- [**Swift**](https://www.swift.org/) 文件头部注释区域、`import` 区域、正文内容区域三者之间必须各空一行；普通单行 `import` 彼此之间保持紧凑，不要空行。
- 保护性导入块和普通单行 `import` 之间必须保留一行空行，例如平台导入块结束后空一行再写 `import JobsSwiftDSL`；普通单行 `import` 写完后，如需接纯导入用途的 `#if canImport(...)` 块，也要先空一行。
- `#if os(OSX)` / `#elseif os(iOS) || os(tvOS)` / `#endif` 平台导入块必须连贯，只能包含 `import AppKit` 和 `import UIKit`，不要把 `typealias`、类、结构体、扩展、变量或业务代码插进去。
- `typealias` 等平台差异声明要单独成块，写在 `import` 区域下面的正文区域；它与 `import` 区域之间保留一行空行。
- 纯导入用途的 `#if canImport(...)` 块统一放在所有普通 `import` 的最下面；如果 `canImport` 块包住的是类、扩展、`@main` 或其它业务代码，则按业务条件编译处理，不要当成 `import` 块移动。

- 控制器统一继承 `BaseVC`。除非项目已有更具体的 Jobs 基类，否则不要直接继承 `UIViewController`。
- 本地 Pod 化框架默认按项目既有能力引入：`JobsByUIKit` 提供 UI / 链式调用 / 导航栏等能力，`JobsSwiftBlock` 提供闭包封装能力。缺依赖时先检查 `Podfile` / 本地 Pods，不要在业务文件里绕开封装重新实现。

### 7.2、代码块 + 懒加载写法

- UI 属性优先使用“代码块闭包 + `lazy var`”的形式创建，初始化、基础配置、事件绑定尽量收口在同一个代码块里，避免在 `viewDidLoad` 里堆散代码。

  ```swift
  private lazy var demoView: UIView = {
      let view = UIView()
      view.backgroundColor = .clear
      return view
  }()
  ```

- 懒加载代码块里只做对象创建、基础属性和轻量事件绑定；涉及布局、网络、复杂业务状态时，放到独立方法里，避免闭包变成第二个 `viewDidLoad`。
- 需要使用 `self` 的闭包要明确引用策略：UI 初始化闭包尽量不捕获 `self`；事件闭包默认 `[weak self]`，布局闭包按项目现有生命周期可使用 `[unowned self]`。

### 7.3、[**SnapKit**](https://github.com/SnapKit/SnapKit) 与 `byAddTo` 约束写法

- 约束默认使用 [**SnapKit**](https://github.com/SnapKit/SnapKit)，不要混用原生 `NSLayoutConstraint`、`frame` 魔法值和散落约束。
- 约束写进 Jobs 自己封装的 `byAddTo` API 里，添加视图和布局约束同步完成。

  ```swift
  demoView.byAddTo(view) { [unowned self] make in
      if view.jobs_hasVisibleTopBar() {
          make.top.equalTo(self.gk_navigationBar.snp.bottom).offset(10)
          make.left.right.bottom.equalToSuperview()
      } else {
          make.edges.equalToSuperview()
      }
  }
  ```

- 外层需要通过 `xxx.byVisible(YES)` 触发可见 / 唤醒时，按项目现有 API 调用；不要为了临时显示视图绕开封装直接改 `isHidden`。

  ```swift
  demoView.byVisible(YES)
  ```

- 约束优先表达“相对关系”，不要写死屏幕尺寸。遇到导航栏、顶部栏、底部安全区，优先使用现有封装方法判断，例如 `jobs_hasVisibleTopBar()`、`gk_navigationBar.snp.bottom`。

### 7.4、导航栏配置写法

- 导航栏统一使用 Jobs 自己封装的 `jobsSetupGKNav` API；简单页面只关心标题时使用简化配置。

  ```swift
  jobsSetupGKNav(title: "这里写标题")
  ```

- 复杂页面使用完整配置，把左右按钮、图片、点按、追加点按、长按等行为直接挂到链式 API 上，避免散落到多个选择器方法里。

  ```swift
  jobsSetupGKNav(
      title: "Demo 列表",
      leftButton: UIButton.sys()
          .byFrame(CGRect(x: 0, y: 0, width: 32.w, height: 32.h))
          .byImage("list.bullet".sysImg, for: .normal)
          .byImage("list.bullet".sysImg, for: .selected)
          .onTap { [weak self] sender in
              guard let self else { return }
              sender.isSelected.toggle()
              self.jobsSideDrawer?.toggleDrawer()
          }
          .onTapAppend { sender in
              print("追加的点按事件")
          }
          .onLongPress(minimumPressDuration: 0.8) { btn, gr in
              if gr.state == .began {
                  btn.alpha = 0.6
                  print("长按开始 on \(btn)")
              } else if gr.state == .ended || gr.state == .cancelled {
                  btn.alpha = 1.0
                  print("长按结束")
              }
          }
          .onLongPressAppend(minimumPressDuration: 0.8) { btn, gr in
              print("追加的长按事件")
          },
      rightButtons: [
          UIButton.sys()
              .byImage("moon.circle.fill".sysImg, for: .normal)
              .byImage("moon.circle.fill".sysImg, for: .selected)
              .onTap { sender in
                  sender.isSelected.toggle()
                  guard let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                        let win = ws.windows.first else { return }
                  win.overrideUserInterfaceStyle =
                      (win.overrideUserInterfaceStyle == .dark) ? .light : .dark
              },
          UIButton.sys()
              .byImage("globe".sysImg, for: .normal)
              .byImage("globe".sysImg, for: .selected)
              .onTap { [weak self] sender in
                  guard let self else { return }
                  sender.isSelected.toggle()
                  tableView.reloadData()
              }
      ]
  )
  ```

- 导航栏按钮事件默认用闭包表达。普通点按用 `.onTap`，追加点按用 `.onTapAppend`，普通长按用 `.onLongPress`，追加长按用 `.onLongPressAppend`。
- 事件闭包里先处理 `guard let self else { return }`，再写业务逻辑；不要在按钮链式配置里塞过长业务代码，复杂逻辑下沉到独立方法。

### 7.5、控制器组织方式

- `viewDidLoad` 只做主流程编排：导航栏配置、视图唤醒、数据绑定、首屏请求。不要把子视图创建、约束、事件、业务判断全部堆进去。
- 推荐控制器结构按职责分块：系统导入、本地框架导入、类声明、懒加载属性、生命周期、导航栏配置、UI 装配、事件响应、业务方法。
- 视图创建、`byAddTo` 约束、`byVisible(YES)` 唤醒、`jobsSetupGKNav` 导航栏配置，应保持 Jobs 项目现有链式风格，除非用户明确要求切换成原生写法。

### 7.6、`return self` 收口格式

- [**Swift**](https://www.swift.org/) 链式 API / DSL 方法里，如果最后一行是 `return self`，且上一行刚好是闭包或代码块收口的右括号 `}`，则 `return self` 不单独成行，必须紧跟上一行右括号后面写成 `};return self`。

  ```swift
  @discardableResult
  func byDownloadProgress(_ block: @escaping JobsYTKProgress) -> Self {
      self.resumableDownloadProgressBlock = { progress in
          block(progress)
      };return self
  }
  ```

- 这条规则只处理 Jobs 自己维护的 [**Swift**](https://www.swift.org/) 代码；外援 Pod 不处理，包括 `Pods/` 目录和 `JobsByPods/ManualBySwiftPods@Pods/` 目录。
