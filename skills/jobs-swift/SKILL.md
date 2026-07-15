---
name: jobs-swift
description: 当任务涉及 Swift、UIButton 创建/配置/事件、JobsByUIKit、JobsSwiftDSL、JobsCor/JobsFont、YES/JobsSwiftBaseDefines、Swift 文件组织、本地 Swift Pod、Core/Resource、点语法链式调用、懒加载、SnapKit、导航栏配置、控制器组织或 Swift return self 收口时使用。
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
- Swift 侧“Jobs 自己写的代码”固定指主工程 + `JobsByPods/` 下 Jobs 自建本地 Pods；排除根目录 `Pods/`、`JobsByPods/ManualBySwiftPods@Pods/` 和确认的外援第三方源码。扫描、批改、回归和编译都按这个边界执行。
- `JobsByUIKit` / `JobsSwiftDSL` 等自建 Pod 里的当前实现是 Swift Jobs API 的唯一权威源；`~/Library/Developer/Xcode/UserData/CodeSnippets` 只是辅助使用记录，不能反过来定义 API。写代码前先核对封装实现，再参考代码块的命名和组织；两者冲突时以最新封装为准，并反哺修正代码块。
- Jobs 自维护的上层 Swift 代码不直接调用已纳入 Jobs 封装体系的系统 API：创建走 `JobsByUIKit` 工厂，属性/方法走 `JobsSwiftDSL`，事件、装配、布局走已有 Jobs 入口。发现系统 API 还没有对应封装时，先在正确的自建 Pod / 类型层补齐封装，再回到调用方落地，不把裸调用当成长期兼容方案。
- 上述限制作用于调用方；`JobsByUIKit` / `JobsSwiftDSL` 等封装的底层实现为了承接系统管线可以调用系统 API，但不得从实现层反向复制裸调用到业务层。每次新写或修改 Swift 代码后，都要按同一映射反扫整个 Swift 自维护范围，不只修被点名文件。
- 值类型和类型推断写法也属于系统 API 调用：基础色、系统调色板和动态语义色已有 `JobsCor` 同名入口时，统一写 `JobsCor.clear`、`JobsCor.white`、`JobsCor.systemRed`、`JobsCor.label`、`JobsCor.secondaryLabel`、`JobsCor.systemBackground`、`JobsCor.systemGray3` 等，不能因编译器能从参数推断 `UIColor` 就保留 `.white` / `.systemRed` / `.label` / `.systemBackground`；RGB、灰度、HSB 颜色使用 `UIColor(r:g:b:a:)` / `UIColor(gray:alpha:)` / `UIColor(h:s:b:a:)` / `UIColor(hex:)`，不得回退到 `UIColor(red:green:blue:alpha:)`、`UIColor(white:alpha:)`、`UIColor(hue:saturation:brightness:alpha:)`。使用 `JobsCor` 的文件必须显式 `import JobsSwiftBaseDefines`，并按本地 Pod 边界补直接依赖。
- 系统字体使用 `JobsSwiftBaseDefines` 的 `JobsFont.systemFont`、`JobsFont.boldSystemFont`、`JobsFont.italicSystemFont`、`JobsFont.monospacedDigitSystemFont`、`JobsFont.monospacedSystemFont`、`JobsFont.preferredFont` 等精确等价入口；不能为了“看起来像 Jobs API”而拿 PingFang、SFPro 或语言字体族替换系统字体并造成字形 / fallback 语义漂移。类型推断的 `.systemFont(...)` 同样要收口；调用文件显式 `import JobsSwiftBaseDefines`。
- 路径创建使用 `JobsByUIKit` 的 `UIBezierPath.make(...)` 重载，路径编排使用 `JobsSwiftDSL` 的 `byMove`、`byAddLine`、`byAddArc`、`byClose`、`byAppend`、`byUsesEvenOddFillRule`、`byFill`；视图动画 / 转场使用 `UIView.jobsAnimate`、`jobsAnimateWithCompletion`、`jobsAnimateWithOptions`、`jobsAnimateWithSpring`、`jobsAnimateKeyframes`、`jobsAddKeyframe`、`jobsPerformWithoutAnimation`、`jobsTransition`、`jobsTransitionFromViewToView`。这些终止动作允许返回 `Void`，调用方不直接使用 `UIView.animate/transition/animateKeyframes/addKeyframe/performWithoutAnimation`。
- 空图片使用 `UIImage.make()`；`UIAction` / `UIMenu` 创建分别使用 `UIAction.make(...)` / `UIMenu.make(...)`；`UIBarButtonItem` 使用当前 `make(title:)`、`make(image:)`、`make(systemItem:)`、`make(customView:)` 及 `flexible()` / `fixed(...)`，不在调用方直接调用系统初始化器。
- Jobs DSL 的第一性是对系统 API 的二次封装。Swift / OC 两侧允许因语言、closure / Block、范型、可选值、返回类型等差异采用不同实现形态，但判断是否应该补 DSL 时，永远先看对应系统 API 是否属于当前类型的覆盖范围，而不是先看另一侧代码是否已经存在同形态实现。
- Swift 侧 DSL 命名与 OC 侧保持同源：统一使用 `by` + 首字母大写的属性名、单参数方法名或一个参数语义名。例如 `text` 对应 `byText(...)`，`font` 对应 `byFont(...)`，`backgroundColor` 优先对应 `byBackgroundColor(...)`。
- 遇到 `Bool` 属性且系统名以 `is` 开头时，DSL 名省略 `is`，例如 `isSelected` 写成 `bySelected(...)`，`isEnabled` 写成 `byEnabled(...)`，保持 Swift / OC 两侧命名平行。
- DSL 覆盖范围不只限于 Apple 原生 API。Jobs 自建 Model、配置对象、业务基础对象也要按同一套思路封装；Swift 侧新增模型 DSL 时，应优先对齐 OC 侧 `JobsModelDSL` 的语义命名和调用方式。
- 对系统 API 进行二次封装成 JobsSwiftDSL 时，覆盖标准是当前类型自己声明的全部属性、0 个入参数方法、1 个入参数方法。父类已有能力放在父类 DSL，不在子类重复铺开；有返回值的方法默认也要返回 `Self` / 当前主对象并标注 `@discardableResult`，除非该能力天然是查询或明确的终止动作。
- Swift 虽然不需要像 OC 一样集中定义大量 Block typedef，但闭包参数命名、返回 `Self`、`@discardableResult` 和链式收口要保持稳定，让调用方可以一路点下去。除明确的终止动作外，Swift DSL 不写只执行副作用却返回 `Void` 的方法；优先返回 `Self` 或当前主对象类型，避免链条中途断掉。
- Swift / OC 两侧面对同一个 Apple API 或同一个 Jobs 自建模型语义时，应尽量保持 DSL 名称、参数语义、调用顺序平行；发现一侧缺失时，优先补齐缺失侧，而不是在业务代码里回退到裸赋值。
- 对“中心对象”配置时，优先围绕一个主接收者一路链式调用。需要配置子对象时，优先提供 `byXxxBlock(...)`、`byXxx { ... }` 或项目既有闭包入口，让闭包内部配置子对象后继续返回主对象；主对象变量名应尽量只作为链式起点出现一次。
- 当一条链中先调用父类 DSL 会导致返回类型降级时，必须先完成当前类本层 DSL，再进入父类 DSL；如果后续仍需要回到子类能力，应补充能返回 `Self` / 主对象的 DSL，而不是拆成第二个接收者调用。
- 视图装配的真实归属要按签名区分：不带约束的 `.byAddTo(superView)` 位于 `JobsSwiftDSL`；带 SnapKit 约束闭包的 `.byAddTo(superView) { make in ... }` 位于 `JobsByUIKit`。纯装配不为使用一参数 API 额外引入 SnapKit，约束重载也不回退到 `addSubview`。
- 写 DSL 示例、Xcode 代码片段和工程配置文档时，点语法以行为最小单位提行书写，方便按行删除或注释。跟在某一行 DSL 后面的解释统一用两根双斜杠 `//`；单独成行的段落说明统一用三根双斜杠 `///`。
- 写 Swift 代码、DSL 示例、`lazy var` 代码块或常见 UI 配置前，先核对实际封装 API，再查看 `~/Library/Developer/Xcode/UserData/CodeSnippets` 下是否已有可复用的 Xcode 代码块；代码块未过时时，优先沿用其命名、占位符和链式组织方式。
- 如果本轮更新了 Swift 侧封装、JobsSwiftDSL、导航栏 API、事件闭包或固定写法，必须同步检查并反哺 `~/Library/Developer/Xcode/UserData/CodeSnippets` 里的相关 `.codesnippet`，让代码块示例跟真实 API 保持一致；不要让片段继续传播旧封装、旧命名或散落赋值写法。
- `~/Library/Developer/Xcode/UserData/CodeSnippets` 里的 Swift 代码片段默认采用“全暴露写法”：常用配置、事件、装配、约束和兼容分支尽量完整列出，让使用者按需求删除或注释，不让使用者临场补 API。片段必须优先传播 JobsSwiftDSL、JobsByUIKit、JobsSwiftBlock 和项目既有导航/事件封装，不能为了示例短而退回裸系统 API。
- 每次完善或纠错 Swift 代码片段后，必须按同一写法反扫 Swift 工程应用层，重点查 `rowHeight =`、`contentInset =`、`scrollIndicatorInsets =`、`contentInsetAdjustmentBehavior =`、`backgroundColor =`、`delegate =`、`dataSource =` 等已有 DSL 覆盖的裸赋值。命中 Jobs 自己维护的主工程或本地 Swift Pod 代码时改成链式；外援 `Pods/`、`ManualBySwiftPods@Pods/` 和确认为第三方源码的目录不处理。
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
- 默认坚持“一个文件一个类型”。除非是同一主类型的短 extension、私有 enum、typealias、轻量协议或确实必须和主类型同文件表达的局部声明，否则不要把多个独立 class / struct / enum 写进同一个 `.swift` 文件。
- 控制器文件尤其不能顺手塞 model、cell、view、helper class。发现 `*VC.swift`、`ViewController*.swift`、`*Cell.swift` 里混入独立类型时，优先拆成独立文件，并按真实职责放到同目录或 `Model` / `View` / `Cell` 子目录。
- 拆出来的 Swift 类型必须使用真实类型名文件名、完整 Jobs 文件头和最小必要 `import`。新增主工程文件时要同步检查 Xcode 文件引用和 target membership；新增 Swift Pod 文件时同步检查 podspec / Podfile / README / 生成物刷新边界。
- 本地 Swift Pod / Swift 工程源码遵循“类型或成组文件用同名目录包裹”：一个类型的主 `.swift`、同名 extension、资源适配文件，或混编时同一基名的 `.h` / `.m` 成组文件，不在功能目录根部平铺散落；用不含后缀名的稳定名称建目录，例如 `JobsRefreshConfig/JobsRefreshConfig.swift`。聚合入口、README、podspec、Package 清单等根入口文件可以留在根部。
- `Core` 只放代码且只能有一层真实目录，禁止磁盘上出现 `Pod名@Pods/Core/Core/...`，也不要用 podspec / Package / Xcode 分组再虚拟包一层 `Core`。移动后同步 podspec / Package / Xcode 引用、README / SwiftDoc 和 Development Pods 展示。
- `Resource` 和 `Core` 平级，承载 `*.plist`、`*.xcprivacy`、图片、字体、音视频、`*.bundle`、`*.xcassets`、`*.strings`、`*.json` 等非代码资源；`Resource` 是真实磁盘目录，不是 podspec / Package 虚拟分组，没有资源时不强制创建。
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

- [**Swift**](https://www.swift.org/) 文件头部注释、`import` 区域、正文区域三者之间各空一行；普通单行 `import` 彼此紧凑，不留空行。
- 平台导入块、普通 `import`、纯导入用途的 `#if canImport(...)` 块之间各空一行；`#if os(OSX)` / `#elseif os(iOS) || os(tvOS)` / `#endif` 平台导入块只能包含 `import AppKit` 和 `import UIKit`。
- `typealias` 等平台差异声明写在正文区域，和 `import` 区域之间保留一行空行；如果 `canImport` 块包住类、扩展、`@main` 或其它业务代码，则按业务条件编译处理，不当成导入块移动。
- 本地 Pod 化框架默认按项目既有能力引入：`JobsByUIKit` 提供 UI / 链式调用 / 导航栏等能力，`JobsSwiftBlock` 提供闭包封装能力。缺依赖时先检查 `Podfile` / 本地 Pods，不要在业务文件里绕开封装重新实现。

### 1.3、`UIButton` 强制封装与 `YES` 导入

- Swift 项目中 Jobs 自己维护的主工程和本地 Swift Pod，只要创建、配置或驱动 `UIButton`，必须使用 `JobsByUIKit` 和 `JobsSwiftDSL` 已有封装，禁止在调用方直接使用系统初始化、属性赋值、`setXxx(...)`、`addTarget(...)`、`UIAction` 或 `sendActions(for:)`。固定排除根目录 `Pods/` 和 `JobsByPods/ManualBySwiftPods@Pods/`；确认为外援第三方源码的目录也不改。
- 按钮创建优先使用 `JobsByUIKit` 工厂：`.system` 对应 `UIButton.sys()`，`.custom` 对应 `UIButton.custom()`，其它系统类型对应 `UIButton.close()`、`.detailDisclosure()`、`.infoLight()`、`.infoDark()`、`.contactAdd()`。调用方禁止写 `UIButton()`、`UIButton(frame:)`、`UIButton(type:)` 或 `UIButton(configuration:)`；如现有工厂缺少某种初始化语义，先在 `JobsByUIKit` 补齐工厂，再回到调用方使用。
- 标题、字体、颜色、图片、背景图、边距、对齐、配置和状态分别使用 `.byTitle(...)`、`.byAttributedTitle(...)`、`.byTitleFont(...)`、`.byTitleColor(...)`、`.byImage(...)`、`.byBgImage(...)`、`.byContentEdgeInsets(...)`、`.byImageEdgeInsets(...)`、`.byTitleEdgeInsets(...)`、`.byContentHorizontalAlignment(...)`、`.byConfiguration(...)`、`.bySelected(...)`、`.byToggleSelected()`、`.byEnabled(...)` 等 DSL。读取状态优先使用 Jobs 查询入口，例如 `jobs_effectiveState`。遇到尚未覆盖的 `UIButton` 系统 API，先补到 `JobsSwiftDSL` / `JobsByUIKit`，不得在业务代码中回退到裸系统 API。
- 点按、追加点按、长按、追加长按分别使用 `.onTap`、`.onTapAppend`、`.onLongPress`、`.onLongPressAppend`；代码触发点按使用 `.performTap()`。
- `UIButton` 调用方至少显式 `import JobsByUIKit`；当前 `JobsByUIKitDSLBridge` 会 `@_exported import JobsSwiftDSL`，因此按钮代码可直接使用 `byXxx`。纯 `JobsSwiftDSL` 消费方或未引入 `JobsByUIKit` 的本地 Pod 要显式 `import JobsSwiftDSL`，不依赖无关 Pod 的传递导入。
- Swift 中的 `YES` 是 `JobsSwiftBaseDefines` 为对齐 OC 写法提供的全局常量。任何在可执行 Swift 代码中使用 `YES` 标识符的 `.swift` 文件，都必须显式 `import JobsSwiftBaseDefines`，不依赖其它 Pod 转导出；定义 `YES` 本身的文件、注释或字符串里的 `"YES"` 不算使用。
- 每次触碰 Swift 按钮或 `YES` 用法后，必须反扫整个 Swift 归属工程并人工剔除注释/字符串误报；不只扫本轮修改文件。

  ```swift
  import JobsByUIKit
  import JobsSwiftBaseDefines
  private lazy var actionButton: UIButton = {
      UIButton.sys()
          .byTitle("确定")
          .byTitleFont(JobsFont.systemFont(ofSize: 16, weight: .semibold))
          .byTitleColor(JobsCor.white)
          .byEnabled(YES)
          .onTap { [weak self] sender in
              guard let self else { return }
              self.submit(sender)
          }
  }()
  ```

### 1.4、代码块 + 懒加载写法

- 子视图默认使用“代码块闭包 + `lazy var`”创建和配置；初始化、基础属性、轻量事件绑定尽量收口在同一个代码块里，装配方法只负责触发懒加载、添加层级、部署约束或做极少量编排。
- 懒加载闭包内部必须用 JobsSwiftDSL 和项目既有 `byXxx` / `byAddTo` / SnapKit 收口：创建、配置、事件、进入父视图、约束链式完成。当前类型缺 DSL 时先补封装，不回退成散落的 `let view = UIView(); view.xxx = ...; parent.addSubview(view)`。

  ```swift
  private lazy var demoView: UIView = {
      UIView()
          .byBackgroundColor(JobsCor.clear)
          .byAddTo(view) { make in
              make.edges.equalToSuperview()
          }
  }()
  ```

- 懒加载代码块不要变成第二个 `viewDidLoad`；涉及布局、网络、复杂业务状态时放到独立方法里。需要使用 `self` 的闭包要明确引用策略：UI 初始化闭包尽量不捕获 `self`；事件闭包默认 `[weak self]`，布局闭包按项目现有生命周期可使用 `[unowned self]`。

### 1.5、[**SnapKit**](https://github.com/SnapKit/SnapKit) 与 `byAddTo` 约束写法

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

#### 1.5.1、无警告约束与临时布局阶段

- 新写或修改 UI 后，必须检查控制台 `Unable to simultaneously satisfy constraints`、`UIView-Encapsulated-Layout-*` 和 `UITableViewAlertForLayoutOutsideViewHierarchy`。按日志中的文件名、行号和视图层级反查创建点；禁止靠删除已成立的业务约束或关闭系统日志掩盖问题。
- `UITableViewCell` / `UICollectionViewCell` 在系统测量阶段可能临时获得 `44` 或 `0` 的封装高度。固定头部高度、折叠内容高度、上下边距等业务约束如果只在真实行高下成立，保留数值但把可压缩的一条设为 `999`；真实高度到位后布局不变，临时阶段让系统封装约束优先。
- 折叠容器不能同时以必选优先级声明“内容高度为 `0`”和“顶部、底部均保留正间距”。零高度约束或非关键底边约束使用 `999`，展开时只更新已保存的高度 `Constraint`，不重复叠加新约束。
- 视图或 TableView 尚未挂到 `window` 时，不调用 `layoutIfNeeded()`、`beginUpdates/endUpdates` 或为了主题刷新而 `reloadData()`。初始化阶段只准备数据；需要强制布局或刷新时用 `view.window != nil` 守卫，或延后到 `viewDidAppear` / `didMoveToWindow`。
- 首次创建用 `makeConstraints` / `byAddTo`，仅常量变化用保存的 `Constraint.update`，结构切换才用 `remakeConstraints`。禁止在复用、配置或 `layoutSubviews` 中反复 `makeConstraints` 叠加同义约束。
- 导航控制器、TabBar 子控制器和自定义 titleView 未获得真实容器尺寸时，不主动强制导航栏布局。根控制器切换先完成 `window.rootViewController` 和 `makeKeyAndVisible`，再刷新依赖真实宽高的 titleView、列表和安全区布局。

### 1.6、导航栏配置写法

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
              sender.byToggleSelected()
              self.jobsSideDrawer?.toggleDrawer()
          }
          .onTapAppend { sender in
              print("追加的点按事件")
          }
          .onLongPress(minimumPressDuration: 0.8) { btn, gr in
              if gr.state == .began {
                  btn.byAlpha(0.6)
                  print("长按开始 on \(btn)")
              } else if gr.state == .ended || gr.state == .cancelled {
                  btn.byAlpha(1.0)
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
                  sender.byToggleSelected()
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
                  sender.byToggleSelected()
                  tableView.reloadData()
              }
      ]
  )
  ```

- 导航栏按钮事件默认用闭包表达。普通点按用 `.onTap`，追加点按用 `.onTapAppend`，普通长按用 `.onLongPress`，追加长按用 `.onLongPressAppend`。
- 事件闭包里先处理 `guard let self else { return }`，再写业务逻辑；不要在按钮链式配置里塞过长业务代码，复杂逻辑下沉到独立方法。

#### 1.6.1、图标资源规则

- Swift 项目中需要用到 UI 图标时，优先复用项目已有图标库、命名和视觉风格；图标可使用 SF Symbols 等系统图标，也可来自 [**iconfont**](https://www.iconfont.cn/)，不随手使用来源不明的图片素材。
- Swift Demo 入口页面中，每个 cell 前的图标必须与当前入口内容及功能语义贴合，并保证同一页面内不重复；来自 [**iconfont**](https://www.iconfont.cn/) 的图标必须下载到本地并放入当前工程实际使用的 `*.xcassets`，禁止通过 URL 或其它方式远程引用。
- 新图标落地时，按当前项目资源体系放入 `Assets.xcassets`、自建 Pod 的 `Resource` / resource bundle 或既有图标目录，并同步 Xcode 文件引用、podspec 资源声明和 README / SwiftDoc 资源说明。
- 如果采用字体图标方式集成，要记录并统一维护图标名称、unicode / class 信息；业务代码里不要散落硬编码 codepoint，优先通过统一常量、枚举、模型或封装入口引用。

### 1.7、控制器组织方式

- `viewDidLoad` 只做主流程编排：导航栏配置、视图唤醒、数据绑定、首屏请求。不要把子视图创建、约束、事件、业务判断全部堆进去。
- 控制器统一继承 `BaseVC`。除非项目已有更具体的 Jobs 基类，否则不要直接继承 `UIViewController`。
- 推荐控制器结构按职责分块：系统导入、本地框架导入、类声明、懒加载属性、生命周期、导航栏配置、UI 装配、事件响应、业务方法。
- 视图创建、`byAddTo` 约束、`byVisible(YES)` 唤醒、`jobsSetupGKNav` 导航栏配置，应保持 Jobs 项目现有链式风格，除非用户明确要求切换成原生写法。

### 1.8、`return` 收口格式

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

### 1.9、本地 Swift Pod 修改后的工程同步扫描

- 但凡修改本地 Swift Pod，不管是新增、删除、重命名、调整源码、公开 API、资源、podspec、`Podfile.deps` 还是依赖关系，都必须扫描整个 Swift 归属工程里使用到这个 Pod 的代码并同步更新。不能只改 `JobsByPods/Pod名@Pods` 目录，也不能只改 podspec。
- 扫描范围至少包括主工程源码、Demo 入口、`import Pod名`、类型名 / 方法名调用、其它 Pod 的 podspec 依赖、`Podfile` / `Podfile.deps`、README / SwiftDoc / 技术文档和脚本中的 Pod 名。涉及重命名时，要同步处理目录名、文件名、类名、菜单文案和依赖声明，避免源码里留下旧名。
- `Pods/`、`Podfile.lock`、`PodspecDependencyReport` 等生成物如果本轮没有执行 `pod install` 或报告生成流程，不手工硬改，但最终必须明确标出仍需刷新；如果执行了生成流程，则要把生成物里的旧 Pod 引用一起确认干净。

### 1.10、Swift 项目 `Podfile` / `Podfile.deps` 脚本边界

- Swift 项目的 `Podfile.deps` 只维护 `pod` 依赖定义，不直接执行外部脚本；外部脚本统一由 `Podfile` 调用，避免依赖清单掺入副作用。
- `Podfile` 中所有 `ScriptsByPods`、`.command`、`.sh`、`.rb` 脚本调用，以及 `load` 外部 Ruby 文件，都必须先判断文件是否存在。脚本不存在、`chmod +x` 失败或脚本执行失败时，默认只打印告警并跳过，不影响 `pod install` 主流程。
- Flutter / Unity / CodeGraph / PodspecDependencyReport 这类脚本都按可选增强处理；只有用户明确指定某脚本是强制门禁时，才允许 `raise` 阻塞。
- 新增脚本入口优先复用 `jobs_run_external_script(...)` 等统一 helper，避免在 `Podfile` 中散落裸 `system(script_path)`。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
