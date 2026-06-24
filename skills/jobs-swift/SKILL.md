---
name: jobs-swift
description: 当任务涉及 Swift、Swift 文件组织、JobsSwiftDSL、点语法链式调用、懒加载、SnapKit、导航栏配置、控制器组织或 Swift return self 收口时使用。
---

# Jobs Swift 写作规范

![Jobs出品，必属精品](https://picsum.photos/1500/400)

[toc]

---

## 🔥 <font id=前言>前言</font>

> 本技能由 `💻JobsCodexConfigs/AGENTS.md` 拆分而来，保留原有 Jobs 工作规范。只有当前任务命中本技能描述时才加载本文件，避免把所有细则长期塞进全局上下文。

## 一、[**Swift**](https://www.swift.org/) 写作规范 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 1.1、Jobs DSL 总体思想

- Jobs 的 Swift / OC DSL 本质是一套命名和调用思想：用点语法 + 链式语法让对象从创建、配置、事件、装配到布局尽量一路设置下去，减少散落赋值和割裂的中间变量。
- Swift 侧 DSL 命名与 OC 侧保持同源：统一使用 `by` + 首字母大写的属性名、单参数方法名或一个参数语义名。例如 `text` 对应 `byText(...)`，`font` 对应 `byFont(...)`，`backgroundColor` 优先对应 `byBackgroundColor(...)`。
- 遇到 `Bool` 属性且系统名以 `is` 开头时，DSL 名省略 `is`，例如 `isSelected` 写成 `bySelected(...)`，`isEnabled` 写成 `byEnabled(...)`，保持 Swift / OC 两侧命名平行。
- DSL 覆盖范围不只限于 Apple 原生 API。Jobs 自建 Model、配置对象、业务基础对象也要按同一套思路封装；Swift 侧新增模型 DSL 时，应优先对齐 OC 侧 `JobsModelDSL` 的语义命名和调用方式。
- Swift 虽然不需要像 OC 一样集中定义大量 Block typedef，但闭包参数命名、返回 `Self`、`@discardableResult` 和链式收口要保持稳定，让调用方可以一路点下去。除明确的终止动作外，Swift DSL 不写只执行副作用却返回 `Void` 的方法；优先返回 `Self` 或当前主对象类型，避免链条中途断掉。
- Swift / OC 两侧面对同一个 Apple API 或同一个 Jobs 自建模型语义时，应尽量保持 DSL 名称、参数语义、调用顺序平行；发现一侧缺失时，优先补齐缺失侧，而不是在业务代码里回退到裸赋值。
- 对“中心对象”配置时，优先围绕一个主接收者一路链式调用。需要配置子对象时，优先提供 `byXxxBlock(...)`、`byXxx { ... }` 或项目既有闭包入口，让闭包内部配置子对象后继续返回主对象，避免主链被 `object.child.xxx` 打断。
- “一链到底”是 Jobs DSL 改造的终结标准：在一个 lazy 初始化闭包、创建闭包或配置闭包里，主对象变量名应尽量只作为链式起点出现一次，例如 `label.byText(...).byFont(...).byAddTo(...)`；后续不再散落 `label.xxx = ...`、`label.method(...)` 或第二段 `label.byXxx(...)`。
- 当一条链中先调用父类 DSL 会导致返回类型降级时，必须先完成当前类本层 DSL，再进入父类 DSL；如果后续仍需要回到子类能力，应补充能返回 `Self` / 主对象的 DSL，而不是拆成第二个接收者调用。
- 写 DSL 示例、Xcode 代码片段和工程配置文档时，点语法以行为最小单位提行书写，方便按行删除或注释。跟在某一行 DSL 后面的解释统一用两根双斜杠 `//`；单独成行的段落说明统一用三根双斜杠 `///`。
- DSL 示例颗粒度必须细：一个属性、一个状态、一个事件、一个装配动作分别独立成行，不把标题、颜色、字体、图片、内边距等多个意图合并到一行。若同一能力同时存在单参数和二参数写法，默认首选单参数写法；二参数写法只在确实需要表达 `.selected`、`.disabled`、`.highlighted` 等非默认状态差异时使用。

### 1.2、文件基座与依赖导入

- Jobs 自己维护的 [**Swift**](https://www.swift.org/) 文件顶部注释必须使用完整 Jobs 模板：第一行文件名，第二行模块名，第三行空注释行，第四行 `Created by Jobs on yyyy年M月d日，星期X.`。新建文件、迁移文件、整理旧文件或用户点名头注释不规范时，都要补齐；不要保留只有文件名和模块名的简化头。文件头注释区域和 `import` 导入区域之间必须保留一个空行，不能让注释块的最后一行 `//` 紧贴 `import`。

  ```swift
  //
  //  JobsClass.swift
  //  JobsClass
  //
  //  Created by Jobs on 2026年5月13日，星期三.
  //

  import UIKit
  ```

- 模板中的文件名必须匹配当前文件真实名称；模块名优先写当前类型、功能模块或所属框架的稳定名称，不确定时先参考同目录同类文件，不要机械写成占位的 `JobsClass`。
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

### 1.3、代码块 + 懒加载写法

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

### 1.4、[**SnapKit**](https://github.com/SnapKit/SnapKit) 与 `byAddTo` 约束写法

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

### 1.5、导航栏配置写法

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

### 1.6、控制器组织方式

- `viewDidLoad` 只做主流程编排：导航栏配置、视图唤醒、数据绑定、首屏请求。不要把子视图创建、约束、事件、业务判断全部堆进去。
- 推荐控制器结构按职责分块：系统导入、本地框架导入、类声明、懒加载属性、生命周期、导航栏配置、UI 装配、事件响应、业务方法。
- 视图创建、`byAddTo` 约束、`byVisible(YES)` 唤醒、`jobsSetupGKNav` 导航栏配置，应保持 Jobs 项目现有链式风格，除非用户明确要求切换成原生写法。

### 1.7、`return` 收口格式

- [**Swift**](https://www.swift.org/) 代码里，只要 `return ...` 紧跟在闭包、控制块、循环块或其它内部代码块的右花括号 `}` 后面，就不单独成行，必须紧跟在上一行右括号后面写成 `};return ...`。`}` 和 `return` 中间的分号不能省略，`}return ...` 是错误写法。这条规则覆盖所有返回值，不只限于 `return self`。
- 如果后花括号 `}` 所在行出现 `//` 或 `///` 注释，则不应用本节 `};return` 紧凑规则；因为在 [**Xcode**](https://developer.apple.com/xcode) 里 `//` 和 `///` 都是注释，下一行 `return ...` 必须保持单独成行，不能提到注释行后面。

  ```swift
  @discardableResult
  func byDownloadProgress(_ block: @escaping JobsYTKProgress) -> Self {
      self.resumableDownloadProgressBlock = { progress in
          block(progress)
      };return self
  }
  ```

- 这条规则只处理 Jobs 自己维护的 [**Swift**](https://www.swift.org/) 代码；外援 Pod 不处理，包括 `Pods/` 目录和 `JobsByPods/ManualBySwiftPods@Pods/` 目录。
- 每次写 Swift 代码或批量改 Swift 文件后，如果触碰了 Jobs 自己维护的 `.swift` 文件，必须在目标范围内扫描 `}\nreturn` 和 `}return` 残留；优先使用 `rg -n -U "\\}\\n\\s*return\\b|\\}return\\b" <目标路径>`，命中后按本节规则修正。

### 1.8、Swift 项目 `Podfile` / `Podfile.deps` 脚本边界

- Swift 项目的 `Podfile.deps` 只维护 `pod` 依赖定义，不直接执行外部脚本；外部脚本统一由 `Podfile` 调用，避免依赖清单掺入副作用。
- `Podfile` 中所有 `ScriptsByPods`、`.command`、`.sh`、`.rb` 脚本调用，以及 `load` 外部 Ruby 文件，都必须先判断文件是否存在。脚本不存在、`chmod +x` 失败或脚本执行失败时，默认只打印告警并跳过，不影响 `pod install` 主流程。
- Flutter / Unity / CodeGraph / PodspecDependencyReport 这类脚本都按可选增强处理；只有用户明确指定某脚本是强制门禁时，才允许 `raise` 阻塞。
- 新增脚本入口优先复用 `jobs_run_external_script(...)` 等统一 helper，避免在 `Podfile` 中散落裸 `system(script_path)`。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
