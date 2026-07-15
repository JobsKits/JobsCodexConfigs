---
name: jobs-objective-c-pods
description: 当任务涉及 Objective-C、系统 API 的 JobsMake/JobsOCDSL 封装、Xcode CodeSnippets 对齐、本地 Pods、Core/Support/Resource、头文件引用、Pod 拆分、JobsDefineProperty、JobsModelDSL、JobsBlock、import 排序或 Xcode Markdown 引用时使用。
---

# Jobs Objective-C 与本地 Pods 工程规范

![Jobs出品，必属精品](https://picsum.photos/1500/400)

[toc]

---

## 🔥 <font id=前言>前言</font>

> 本技能由 `💻JobsCodexConfigs/AGENTS.md` 拆分而来，保留原有 Jobs 工作规范。只有当前任务命中本技能描述时才加载本文件，避免把所有细则长期塞进全局上下文。

## 一、[**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) / 本地 Pods 工程规范 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 1.1、工程背景与目录边界

- 本规范默认服务 Jobs 的 OC 工程，尤其是把原工程里的本地代码逐步提取为本地管理 Pods 的场景。
- Swift 侧的 iOS 项目固定指 `../../../../JobsBaseConfig/JobsBaseConfig@JobsSwiftBaseConfigDemo`。
- OC 侧的新项目固定指 `../../../../JobsOCBaseConfigDemo@ByPods`。
- OC 侧的老项目固定指 `../../../../JobsBaseConfig/JobsBaseConfig@JobsOCBaseConfigDemo`。
- OC 新项目由 OC 老项目升级改造而来：新项目把老项目中集成于主工程的一部分能力拆解成本地 Pods 管理，拆解过程中只做极小调整，绝大多数新项目本地 Pod 都能在老项目主工程里找到对应来源或对应功能。
- 从 OC 新项目向 OC 老项目平移能力时，要按老项目的主工程集成方式落地：不要把新项目的 `Pod名@Pods` 目录、podspec 或 Podfile 依赖照搬成老项目的新 Pod；应把源码放回老项目主工程的对应功能目录，把资源加入老项目资源目录，把 Demo 入口、聚合头、Build Phases 和 target 引用同步到老项目现有结构。
- OC 新项目里“Jobs 自己写的代码”定义为主工程 + `JobsByPods/` 下 Jobs 自建本地 Pods；排除根目录 `Pods/`、`JobsByPods/ManualByOCPods@Pods/` 和确认的外援第三方源码。扫描、批改、回归和编译都按这个边界执行。
- 所有本地管理的 Pod 默认位于项目根目录 `JobsByPods` 文件夹下，每个 Pod 文件夹命名统一为 `Pod名@Pods`。
- 外源性 Pod 本地化后，统一放入 `JobsByPods/ManualByOCPods@Pods` 管辖。第三方来源信息要保留，只做本地托管适配，不抹掉上游痕迹。
- `JobsByPods/ManualByOCPods@Pods/Texture` 是明确的重型第三方 Pod 豁免项，不套用 Jobs 自建 Pod 的 `Core` / `Support` / `Resource`、根聚合头、`JobsPodspecKit.rb` 和 podspec 扁平化规范，也不因全量本地 Pod 整理而移动或改写其上游目录、源码、资源与 subspec。只有用户明确点名修改 `Texture` 本身时才进入该目录，并继续以保留上游结构为优先。
- `JobsByOCPods` 是最初提取出来的本地 Pod，也是后续本地 Pods 分离时的源头参照。遇到缺文件、缺宏、缺分类、缺辅助类时，优先回到 `JobsByOCPods` 找源头，再迁移到目标 Pod 的合适位置。
- 工程最初能完整编译通过的前提，是尚未把部分本地写法提取成多个本地 Pod。拆分后，每个 Pod 实际上成为独立工程，只是通过同一个 `xcworkspace` 协同管理，因此编译器会提高跨域访问门槛，暴露头文件、模块化、依赖边界和循环引用问题。
- 处理编译错误时，不要只追求“先编过”。要判断错误是不是由本地 Pod 化后的边界变化引起：头文件暴露层级、`Core` / `Support` 归属、podspec 依赖、聚合头、`HEADER_SEARCH_PATHS`、循环依赖，都要一起看。
- Jobs 自己维护的 [**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) 文件（`*.h` / `*.m` / `*.mm`）顶部注释必须使用完整 Jobs 模板：第一行文件名，第二行模块名，第三行空注释行，第四行 `Created by Jobs on yyyy年M月d日，星期X.`。新建文件、迁移文件、整理旧文件或用户点名头注释不规范时，都要补齐；不要保留只有文件名和模块名的简化头。文件头注释区域和 `#import` 导入区域之间必须保留一个空行，不能让注释块的最后一行 `//` 紧贴 `#import`。

  ```objc
  //
  //  JobsClass.h
  //  JobsClass
  //
  //  Created by Jobs on 2026年5月13日，星期三.
  //

  #import "JobsClass.h"
  ```

- 模板中的文件名必须匹配当前文件真实名称，例如 `PDFView+DSL.m`；模块名优先写当前类、分类或所属 Pod / 模块的稳定名称，不确定时先参考同目录同类文件，不要机械写成占位的 `JobsClass`。

### 1.2、文件组织与类边界

- 默认坚持“一个文件一个类”。除非是 `NS_INLINE`、小型 `typedef`、私有枚举、协议声明、极短生命周期的匿名 category，或者确实必须和主类共生的编译期兼容声明，否则不要把多个 `@interface` / `@implementation` 写进同一个 `.h` / `.m` 文件。
- 控制器文件尤其不能顺手塞 model、cell、view、helper class。发现 `ViewController*.m`、`*VC.m`、`*Cell.m` 里混入独立类时，优先拆成独立的 `类名.h/.m`，并按真实职责放到同目录或 `Model` / `View` / `Cell` 子目录，再由调用方 `#import` 引用。
- 拆出来的类必须使用真实类名文件名、完整 Jobs 文件头、独立 `@interface` / `@implementation`，公开 API 放 `.h`，实现细节留 `.m`。不要为了省事写在调用方 `.m` 顶部形成“局部类”。
- 如果新增文件属于 Xcode 主工程源码，必须同步检查并更新 `*.xcodeproj/project.pbxproj` 的文件引用和 target membership；如果属于本地 Pod，则按 Pod 目录、podspec、README 和 `pod install` 规则处理。不能只在磁盘上新建文件就结束。
- Jobs 自建 Pod 的磁盘根目录统一为 `Pod名@Pods`：`Core` 必须存在，`Support` / `Resource` 按需创建，不强制空目录；入口头、podspec、README、LICENSE 放在根目录，不放进 `Core` / `Resource`。CocoaPods 的 `Development Pods > Pod名` 只是展示分组，不能当成真实资源目录。
- `Core` 只放代码。Jobs 自建 Pod 的 `Core` 目录下，所有 `*.h` / `*.m` / `*.mm` 源码都必须用完整基名建同名文件夹包裹；同一组 `.h` / `.m` / `.mm` 放进同一个同名文件夹，分类保留 `+Category` 全名，不允许因为同层只有一组就平铺。例如 `Core/JobsFuseAnimation/JobsFuseOuterRingConfig/JobsFuseOuterRingConfig.h` 和 `Core/JobsFuseAnimation/UIView+JobsFuseAnimation/UIView+JobsFuseAnimation.h`。
- 聚合头 / 模块入口头必须放在 `Pod名@Pods/` 根目录，和 `Core` / `Resource` / `Support` 齐平。入口头一般使用 `Pod名.h`；若 `Core/Pod名/Pod名.h` 带同名 `.m` 或真实 `@interface`，它是源码头，不按聚合头硬搬，必须先解决命名冲突和公开头设计，避免同名 public header 互相覆盖。
- `Core` 只能有一层真实目录，禁止磁盘上出现 `Pod名@Pods/Core/Core/...`，也不要用 podspec 虚拟 subspec 再包一层 `Core/**/*`。移动目录后同步检查 podspec 递归通配、公开头边界、README 目录结构和 `pod install` 后的 Development Pods 展示。

### 1.3、`Core` / `Support` 文件夹职责

- `Core` 承载准备对外暴露的核心能力；`Core` 代码头文件通常进入 `public_header_files`，代表使用方能看到的 API 边界。
- `Resource` 和 `Core` 平级，专门承载非代码资源；图片、`*.bundle`、声音文件、`*.json`、`*.plist`、`*.xcprivacy`、`.xcassets`、字体、音视频等都放入真实 `Resource` 目录，不塞进 `Core`，也不只在 podspec 中虚拟分组。
- `Support` 辅助 `Core`，放实现细节、兼容代码、内部分类、桥接文件、局部宏和非公开工具。`Core` 如果必须引用 `Support`，只允许写在 `*.m` / `*.mm` 内，并使用 `<Pod名/Support头文件.h>` 这类尖括号形式。
- 某个 Pod 缺文件时，最合理路径不是立刻新增跨 Pod 引用，而是去源头 `JobsByOCPods` 寻找，迁移到当前 Pod 的 `Support` 文件夹下，并按既定目录格式放入。
- 能放进当前 Pod `Support` 解决的，不要轻易加新的 Pod 依赖。只有该能力确实属于独立公共能力、多个 Pod 都应该复用时，才考虑拆成独立 Pod 或依赖已有 Pod。
- `Core` / `Support` 的真实磁盘目录结构必须能在 [**Xcode**](https://developer.apple.com/xcode) / Pods 工程里显示出来。新增、删除、移动目录后，通过 `JobsPodspecKit.rb` 动态映射，`pod install` 后应反映真实目录结构。

### 1.4、头文件引用边界

- `Core` 引用 `Core`、`Support` 引用 `Support` 时，依赖可写在 `*.h`；`Core` 引用 `Support` 时写在 `*.m` / `*.mm`，避免把内部实现细节泄露到公开头文件。
- 系统头、第三方 Pod、内源 Pod 的公开依赖默认写入当前模块同名 `*.h`；Jobs 自己维护的 `*.m` / `*.mm` 顶部只保留自身同名头文件，以及当前 Pod 内部确需下沉到实现层的 `Support` 私有头。
- 用到其他 Pod 时，一律优先 `__has_include` 双通道保护性写法 + 聚合头，先尝试 `<Pod名/聚合头.h>`，再 fallback 到 `"聚合头.h"`；不要裸写第三方 / 其他 Pod 的内部子头，也不要把保护性 import 留在实现文件。
- 对 `JobsOCDSL`、`JobsMakes`、`JobsModelDSL`、`JobsBlock`、`JobsOCDefs` 这类聚合头，按“必须上提到同名 `*.h`”执行；如果上提后暴露循环依赖，要通过前向声明、依赖下沉、拆 Support 或修 podspec 边界解决，不退回实现文件。
- 头文件只引入当前 `*.h` 真实暴露类型、协议、宏或声明所需要的最小模块；普通实现细节头可留在 `*.m`，但 `__has_include` 保护性 import 和上述 Jobs 聚合头不适用该例外。
- 如果某个 Pod 已经提供聚合头，外部引用必须引入聚合头，不要因为当前只用到其中一个协议、宏、分类或类，就绕开聚合头单独引入内部子头。聚合头是这个 Pod 对外承诺的头文件边界，子头只是聚合头内部组织细节。
- 禁止用“补一个更具体的子头 import”来掩盖 podspec 依赖、公开头暴露、modulemap、`HEADER_SEARCH_PATHS` 或循环依赖问题。例如已经引入 `JobsOCProtocols/JobsBaseProtocolHeader.h` 时，不要再为了 `BaseProtocol` 单独引入 `JobsOCProtocols/BaseProtocol.h`；如果 `BaseProtocol` 仍未声明，应排查 `JobsOCProtocols` 的直接依赖、聚合头导出、Pod 生成物和模块边界。
- 只要某个文件用了 `MacroDef_Cor.h` 里提供的颜色相关能力，例如 `JobsWhiteColor`、`JobsClearColor`、`HEXCOLOR(...)`、`UIColor.xy_*` 等，则该文件的 `*.h` 头文件必须显式补上 `XYColorOC` 的双通道保护性导入；不要只依赖 `*.m`、PCH、别的聚合头或间接包含。

  ```objc
  #if __has_include(<XYColorOC/XYColorOC.h>)
  #import <XYColorOC/XYColorOC.h>
  #else
  #import "XYColorOC.h"
  #endif
  ```

- 这条规则优先作用在公开头文件边界：如果 `MacroDef_Cor.h` 的颜色宏或 `XYColorOC` 能力是在 `*.h` 里被声明、默认值、宏定义、内联函数或点语法签名直接用到，就必须把上面的导入写进对应 `*.h`；只有确定相关能力纯属 `*.m` 内部实现细节时，才允许只在 `*.m` 导入。

  ```objc
  #if __has_include(<JobsOCDefs/JobsDefines.h>)
  #import <JobsOCDefs/JobsDefines.h>
  #else
  #import "JobsDefines.h"
  #endif
  ```

- 不要在公开头里写脆弱的相对路径，例如 `../../xxx.h`。如果必须靠搜索路径才能找到，要回到 podspec / `JobsPodspecKit.rb` / `header_mappings_dir` / 聚合头设计上修正。

### 1.5、本地 Pod 拆分策略

- 拆 Pod 前先确认职责边界：这个能力是公共基础能力、业务 UI、工具分类、模型、宏定义、资源包，还是某个 Pod 的内部辅助实现。职责没分清，不要急着建新 Pod。
- 从 `JobsByOCPods` 分离能力时，优先保持原始文件命名、注释风格和调用方式，先完成边界收口，再考虑小范围整理。
- 新 Pod 目录必须使用 `Pod名@Pods`，内部至少包含 `Core`、`Pod名.podspec`、必要时包含 `Support`、`JobsPodspecKit.rb`、`README.md`、入口头 `Pod名.h`。
- 能用 `Support` 消化的跨域访问问题，优先迁移到当前 Pod `Support`；确实属于可复用公共能力时，才新增 Pod 依赖。
- 对第三方库做 Jobs 风格补充时，优先独立成本地管理的 `Extra` Pod，并以 `Extra` 结尾，例如 `BRPickerViewExtra`、`GKCustomNavigationBarExtra`、`HTMLDocumentExtra`。这些补充不直接改外援源码，优先放入对应 `Extra@Pods/Core`。
- `Extra` Pod 里如果发现继承自 `NSObject`、实质承担配置 / model 职责的第三方类或本地适配类，默认做成 `类名+DSL.h/.m` 的形式并入对应 `Extra` Pod 的 `Core`。每组文件都必须用各自名字命名的文件夹包裹管理，例如 `Core/BRPickerStyle/BRPickerStyle+DSL/BRPickerStyle+DSL.h`；即使该目录下只有 `BRPickerStyle+DSL.h/.m` 这一组，也不允许直接平铺在 `Core/BRPickerStyle/` 下。
- 一个文件只办一件事。遇到历史代码在 `类名+Category.h/.m` 里顺手定义主类、兼容空类、记录类、配置类等独立类型时，必须拆到独立的 `类名.h/.m` 文件；category 文件只保留 category 职责。为防止旧代码或外部库重复定义，兼容类声明和空实现默认用 `#ifndef` 宏保护。
- 批量修改后，如果用户指出一个具体文件的问题，默认按同一套批量规则做全局回归扫描。只要该问题可能由统一脚本、统一替换、统一 import 规则造成，就不能只修被点名文件，要在同一覆盖范围内找同类问题并同步修正。
- 但凡修改本地 Pod，不管是新增、删除、重命名、调整 `Core` / `Support`、公开 API、入口头、资源、podspec、`Podfile.deps` 还是依赖关系，都必须扫描整个归属工程里使用到这个 Pod 的代码并同步更新。扫描范围至少包括主工程源码、Demo 入口、`#import` / 聚合头引用、其它 Pod 的 podspec 依赖、`Podfile` / `Podfile.deps`、README / 技术文档和脚本中的 Pod 名；不能只改 `Pod名@Pods` 目录。`Pods/`、`Podfile.lock`、`PodspecDependencyReport` 等生成物如果本轮没有执行生成流程，不手工硬改，但最终必须明确标出仍需刷新。
- 每次新增、删除或调整 Pod 依赖，都要同步检查直接依赖和第二层以下间接依赖。不要只看当前 podspec 里写了什么，还要看它依赖的 Pod 又依赖了谁。
- 严禁用“互相依赖”解决编译问题。出现循环依赖时，要把公共部分下沉到更底层 Pod，或把内部实现移动到 `Support`，而不是继续堆 `dependency`。
- 调整本地管理的子 Pod、`Podfile`、`Podfile.deps`、`JobsPodspecKit.rb` 或 `post_install` / `post_integrate` 逻辑后，不能只以 `pod install` 不报错作为完成标准。必须额外确认 `Pods/Pods.xcodeproj` 能被 `xcodeproj` 正常打开、`PBXProject` 根对象没有被新文件引用覆盖、`xcodebuild -workspace ... -list` 能列出目标 Pod scheme，并且 Xcode 左侧 `Development Pods > Pod名` 能展开到 `Core` / `Support` / `Pod` / `Support Files` 等真实子项。
- 如果 Xcode 左侧能看到 Pod 名但点击后没有子项，优先怀疑 Pods 工程文件被脚本写坏或 UUID 冲突，而不是怀疑 CocoaPods 没装成功。重点检查 `Podfile` 里手动给 `Pods.xcodeproj` 增加文件引用、移动 group、固定 UUID、补 `Podfile.deps` / 报告文件引用等逻辑；这类增强只能做展示辅助，失败或冲突时应跳过，不能破坏 CocoaPods 生成的 `PBXProject`、root group 和 Development Pods 树。
- 本地子 Pod 的可用性回归至少覆盖三步：`pod install --no-repo-update`、`ruby -rxcodeproj -e 'p = Xcodeproj::Project.open("Pods/Pods.xcodeproj"); puts [p.root_object.isa, p.targets.map(&:name).grep(/Pod名/)].inspect'`、`xcodebuild -workspace 工程.xcworkspace -scheme Pod名 -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build`。如果改动会影响主 App Demo，还要编译主 App scheme。
- Demo 分类或主工程分类不要把试验能力全局污染到所有基础控件。尤其是 `UITableView` / `UICollectionView` 的 `reloadData` swizzle，禁止在分类 `+initialize` 里用 `self` 做交换；要么显式 opt-in，要么在 `+load` 中固定基类并 `dispatch_once` 交换一次，且默认状态必须 no-op。否则新 Pod 的普通 table 也会被 Demo 分类截获，出现点击进入二级页后崩溃、野指针或空数据视图误插入。
- `reloadData` swizzle 必须考虑重入保护。`UITableView` / `UICollectionView` 原始 `reloadData` 可能在 `layoutSubviews`、索引刷新、约束更新或第三方刷新回调里再次触发 `reloadData`；如果 swizzle 方法里直接 `[self jobsReloadData]` 而没有 associated flag 防重入，容易形成 `reloadData -> jobsReloadData -> layoutSubviews -> reloadData` 的递归，最终 `EXC_BAD_ACCESS` 或栈溢出。
- `UITableViewDataSource` / `UITableViewDelegate` 回调里不要为了比较来源而调用 `self.tableView` 这类懒加载 getter。尤其是在懒加载闭包中刚创建 table、尚未赋值给 ivar 时，系统可能立即回调 `sectionIndexTitlesForTableView:`、`heightForHeaderInSection:` 等方法；这时再进 getter 会重复创建 table。应使用 `_tableView` 这类 ivar 做身份比较，避免懒加载重入。

#### 1.5.1、`JobsDefineProperty.h` 属性宏覆盖

- `JobsOCDefs` 是最底层定义 Pod，`JobsDefineProperty.h` 里对系统冗长的 `@property` 做了 `Prop()` / `Prop_strong()` / `Prop_weak()` / `Prop_assign()` / `Prop_copy()` / `Prop_retain()` 简短定义。Jobs 自己维护的代码默认使用这些宏，不再新增系统冗长写法。
- 全局覆盖范围：项目主工程、非 `Pods` 文件夹及其下辖文件、`JobsByPods` 中除 `ManualByOCPods@Pods` 之外的本地管理 Pod。外援 Pod、`Pods/` 生成物、`JobsByPods/ManualByOCPods@Pods/` 下手动托管的第三方源码不做覆盖。用户明确指定旧工程“除了 `Pods` 文件夹下”时，按该工程实际外援边界执行。
- 限定范围内只要出现真实 `@property` 声明，就要替换为属性宏；不只处理 `strong` / `weak` / `assign` / `copy` / `retain`，`readonly`、`readwrite`、`class`、`getter=`、`nullable`、`nonnull` 等属性参数也要并入对应宏参数。属性之间如果没有注释，不保留空行。
- 执行覆盖后要确认使用 `Prop_*()` 的目标头文件直接导入属性宏头，不依赖 `.m`、PCH 或间接包含。新本地 Pod 优先按真实模块导入 `JobsDefineProperty.h` / `JobsOCDefs` 聚合入口；旧主工程如果实际宏头叫 `DefineProperty.h`，就必须写 `#import "DefineProperty.h"`，不要误写成 `JobsDefineProperty.h`。
- 如果某个独立 Pod 因宏不可见编译失败，优先补该 Pod 对 `JobsOCDefs` 的直接依赖和保护性 import，而不是退回系统 `@property` 写法。

### 1.6、Pod README 同步规则

- 每个本地 Pod 都应有自己的 `README.md`，因为每个 Pod 本质上都是相对独立的工程。
- 只要更新 Pod 的 `Core`、`Support`、podspec、依赖、资源、入口头、公开 API，就要同步更新该 Pod 的 `README.md`。
- Pod README 至少说明：用途、适用场景、目录结构、`Core` / `Support` / `Resource` 边界、公开能力、内部辅助能力、依赖关系、引用方式、资源说明、验证方式、风险说明。
- README 不要只写口号。它要能帮助后续排查：这个 Pod 为什么存在、哪些文件是公开的、哪些文件只是内部支撑、缺文件时应该回哪里找、修改依赖后要看哪个报告。

### 1.7、依赖报告与循环引用校正

- Pod 之间的上下依赖关系，会在每次 `pod install` 时通过脚本挂载加载：

  ```text
  ScriptsByPods/【MacOS】🔍查询Xcode工程依赖关系.command/【MacOS】🔍查询Xcode工程依赖关系.command
  ```

- 依赖报告生成物位于：

  ```text
  PodspecDependencyReport
  ```

- 修改或增删本地管理的子 Pod 依赖后，必须查看 `PodspecDependencyReport`，校正上下依赖关系，重点排查循环引用。
- 不能只看第一层依赖。有些风险藏在第二层、第三层或聚合 Pod 之后，需要沿报告仔细甄别。
- 能生成 `PodspecDependencyReport`，说明对应时间点 `pod install` 已执行成功，依赖关系至少在当时是正常的。后续排查“什么时候还正常”时，可以把报告生成时间作为关键节点。
- 如果依赖报告显示链路过长或边界混乱，优先通过下沉公共能力、迁移内部文件到 `Support`、减少公开头引用来修正，而不是继续扩大 `HEADER_SEARCH_PATHS`。

### 1.8、`ScriptsByPods` 脚本约定

- `ScriptsByPods` 存放适用于整个当前工程的脚本，其中一部分会挂载到 `pod install` 后自动运行。
- 因为 [**CocoaPods**](https://cocoapods.org/) 本身使用 [**Ruby**](https://www.ruby-lang.org) 生态，Pod 相关脚本优先使用原生 Shell + Ruby。除非确实没法低成本实现，不要引入 [**Python**](https://www.python.org)、Node.js 或其他额外运行环境。
- 能在 Shell 里稳定完成的路径处理、文件扫描、日志输出、交互确认，不要强行换语言。能在 Ruby 里直接读 podspec / Podfile / CocoaPods 上下文的，不要绕远路。
- 脚本仍然遵守本文 `二、MacOS Shell 脚本` 的基座规则：`# shell: zsh`、路径变量、彩色日志、README 阻塞、防误触、`main "$@"`、危险操作 `YES` 确认、静态检查。
- OC 项目的 `Podfile.deps` 只维护 `pod` 依赖定义，不直接执行外部脚本；外部脚本统一由 `Podfile` 调用，并且必须具备“脚本不存在就跳过、不影响 `pod install` 主流程”的保护。
- `Podfile` 中所有 `ScriptsByPods`、`.command`、`.sh`、`.rb` 脚本调用，以及 `load` 外部 Ruby 文件，都按可选增强处理：脚本缺失、`chmod +x` 失败、脚本执行失败时只打印告警并返回，不用 `raise` 中断。除非用户明确指定强制门禁，否则依赖报告、CodeGraph 等 post-install 脚本都不能阻塞主流程。

### 1.9、`return` 收口格式

- [**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) 代码里，只要 `return ...;` 紧跟在控制块、循环块、枚举块或其它内部代码块的右花括号 `}` 后面，就不单独成行，必须紧跟在上一行右括号后面写成 `};return ...;`。`}` 和 `return` 中间的分号不能省略，`}return ...;` 是错误写法。这条规则覆盖所有返回值，不只限于 `return self;`。
- 如果后花括号 `}` 所在行出现 `//` 或 `///` 注释，则不应用本节 `};return` 紧凑规则；因为在 [**Xcode**](https://developer.apple.com/xcode) 里 `//` 和 `///` 都是注释，下一行 `return ...;` 必须保持单独成行，不能提到注释行后面。
- 这条规则只作用于方法或 Block 内部的代码块收口；不要把方法实现本身的结束花括号、`@implementation` / `@end`、类或结构声明收口误改成 `};return`。
- 这条规则只应用 Jobs 自己写的代码；外援 Pod 不处理，包括 `Pods/` 目录和 `JobsByPods/ManualByOCPods@Pods/` 目录。
- 每次写 OC 代码或批量改 OC 文件后，如果触碰了 Jobs 自己维护的 `.m` / `.mm` 文件，必须在目标范围内扫描 `}\nreturn` 和 `}return` 残留；优先使用 `rg -n -U "\\}\\n\\s*return\\b|\\}return\\b" <目标路径>`，命中后按本节规则修正。用户点名某些模块时，必须覆盖用户点名的全部模块。

  ```objc
  -(JobsRetMutableParagraphStyleByCGFloatBlock _Nonnull)byDefaultTabInterval {
      @jobs_weakify(self)
      return ^__kindof NSMutableParagraphStyle * (CGFloat v) {
          @jobs_strongify(self)
          if (@available(iOS 7.0, tvOS 9.0, watchOS 2.0, visionOS 1.0, *)) {
              self.defaultTabInterval = v;
          };return self;
      };
  }
  ```

  ```objc
  -(NSString *)stableHash:(NSString *)value {
      uint64_t hash = 14695981039346656037ULL;
      const char *string = value.UTF8String;
      while (*string) {
          hash ^= (uint64_t)(unsigned char)(*string++);
          hash *= 1099511628211ULL;
      };return [NSString stringWithFormat:@"%llx", hash];
  }
  ```

- [**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) `*.m` 文件里，`@end` 必须和上方主内容区域之间空一行；不能把 `@end` 紧贴在上一个方法、实现块或右括号下面。

  ```objc
  -(JobsRetJobsBaseModelByJobsByBtnBlockBlock _Nonnull)byCloseBtnClickAction{
      @jobs_weakify(self)
      return ^__kindof JobsBaseModel *_Nullable(jobsByBtnBlock _Nullable data) {
          @jobs_strongify(self)
          self.closeBtnClickAction = data;
          return self;
      };
  }

  @end
  ```

### 1.10、Jobs DSL 总体思想

- Jobs 的 OC / Swift DSL 本质是一套命名和调用思想：用点语法 + 链式语法让对象从创建、配置、事件、装配到布局尽量一路设置下去，减少散落赋值和割裂的中间变量。
- `JobsMakes`、`JobsOCDSL`、`JobsModelDSL` 及相关自建 Pod 里的当前实现是 OC Jobs API 的唯一权威源；`~/Library/Developer/Xcode/UserData/CodeSnippets` 只是辅助使用记录，不能反过来定义 API。写代码前先核对封装实现，再参考代码块；两者冲突时以最新封装为准，并反哺修正代码块。
- Jobs 自维护的上层 OC 代码不直接调用已纳入 Jobs 封装体系的系统 API：创建走 `JobsMake`，属性/方法走 `JobsOCDSL` / `JobsModelDSL`，Block 走 `JobsBlock`，事件、装配、布局走已有 Jobs 入口。发现系统 API 还没有对应封装时，先在正确的自建 Pod / 类型层补齐封装，再回到调用方落地，不把裸调用当成长期兼容方案。
- 当前真实归属要分清：`jobsMakeView`、`jobsMakeLabel`、`jobsMakeImageView`、`jobsMakeTextField`、`jobsMakeCollectionView`、`jobsMakeScrollView` 等通用工厂位于 `JobsMakes`；`jobsMakeButton`、`UIButton.jobsInit()` 与 `jobsResetBtn*` 跨新旧按钮管线入口当前由 `JobsByOCPods` 的 `UIButton+SimplyMake` / `UIButton+UI` 承接，不得误写成 `JobsMakes` 已经导出按钮工厂。
- 值类型、路径、动画和静态构造同样受封装规则约束：字体走 `JobsOCDefs` 的 `UIFontSystemFontOfSize`、`UIFontSystemFontOfSizeAndWeight`、`UIFontWeight*Size`、`UIFontMonospaced*Size`；颜色走 `RGB_COLOR` / `RGBA_COLOR` / `jobsMakeCor2` 等当前封装；贝塞尔路径走 `jobsMakeBezierPath` 或 `UIBezierPath.byBezierPathWithRect/OvalInRect/CGPath/RoundedRect/RoundedCorners/ArcCenter`；视图动画与转场走 `UIView.jobsAnimate/jobsAnimateWithCompletion/jobsAnimateWithOptions/jobsAnimateWithSpring/jobsTransition/jobsTransitionFromViewToView`。调用方不得因这些 API 是类方法或值工厂就继续直调 UIKit。
- `JobsMakes` 当前还负责 `jobsMakeAction`、`jobsMakeMenu`、`jobsMakeMenuByConfiguration`、`jobsMakeContextMenuConfiguration`、`jobsMakeNib`、`jobsMakeBarButtonItemByTitle/ByImage/BySystemItem`、`jobsMakeImage` 等静态构造入口；空贝塞尔路径使用 `jobsMakeBezierPath(nil)`。新增或升级工厂时，以公开头真实签名为准，同时更新直接依赖、README 和 CodeSnippets。
- `UIButton+SimplyMake` / `UIButton+UI` / `UIButton+UIControlState` 在部分 Pod 的 `Support` 中仍有历史副本时，以 `JobsByOCPods/Core/UIKit/UIButton` 当前实现核对 API；canonical 新增、修正按钮 API 时，所有仍参与编译的 Support 副本必须同步并做接口 / 行为对齐，但调用方不得绕过聚合头直接引用私有 `Support`。轻量 Pod 若因循环依赖不能直接依赖 canonical、但已安全依赖 `JobsBaseUI`，可通过其公开聚合头使用 `jobsMakeBaseButton` 并继续用 `JobsOCDSL` 配置；若必须保留 `jobsResetBtn*` 的跨管线语义，则先下沉 / 统一导出封装再调用。不允许退回 `[UIButton new]`、`buttonWithType:`、`setTitle:`、`setImage:` 等系统 API。
- 上述限制作用于调用方；`JobsMakes` / `JobsOCDSL` / `JobsModelDSL` 等封装的底层实现为了承接系统管线可以调用系统 API，但不得从实现层反向复制裸调用到业务层。每次新写或修改 OC 代码后，都要按同一映射反扫整个 OC 自维护范围，不只修被点名文件。
- Jobs DSL 的第一性是对系统 API 的二次封装。OC / Swift 两侧允许因语言、Block / closure、范型、可选值、返回类型等差异采用不同实现形态，但判断是否应该补 DSL 时，永远先看对应系统 API 是否属于当前类型的覆盖范围，而不是先看另一侧代码是否已经存在同形态实现。
- DSL 命名统一使用 `by` + 首字母大写的属性名、单参数方法名或一个参数语义名。例如 `text` 对应 `byText(...)`，`font` 对应 `byFont(...)`，`addSubview:` 这类动作可按既有封装写成 `addOn(...)` / `byAddTo(...)` 等项目内统一语义。
- 遇到 `BOOL` 属性且系统名以 `is` 开头时，DSL 名省略 `is`，例如 `isSelected` 写成 `bySelected(...)`，`isEnabled` 写成 `byEnabled(...)`，保持 Swift / OC 两侧命名平行。
- UIKit 状态和可见性也按属性所属层收口：`UIControl` / `UIButton` 使用 `bySelected(...)`、`byEnabled(...)`、`byHighlighted(...)`，选中态切换使用 `byToggleSelected()`，状态读取使用 `jobs_isSelected` / `jobs_isEnabled` / `jobs_isHighlighted` / `jobs_effectiveState`；`UIView` / `CALayer` 使用各自的 `byHidden(...)`。系统代理已存在 Jobs DSL 时统一走 `byDelegate(...)`，例如 `UINavigationController` 与 `UNUserNotificationCenter`。`UINavigationBarAppearance`、`UITabBarAppearance` 的公共底色能力统一复用父类 `UIBarAppearance.byBackgroundColor(...)`，不在子类或调用方重复裸赋值。
- DSL 覆盖范围不只限于 Apple 原生 API。Jobs 自建 Model、配置对象、业务基础对象也要按同一套思路封装；OC 侧重点体现在 `JobsModel` 的 `JobsModelDSL`，例如 `UIViewModel`、`UITextModel`、`UIButtonModel` 等大 Model / 子 Model 都应支持链式配置。
- 对系统 API 进行二次封装成 JobsOCDSL 时，覆盖标准是当前类型自己声明的全部属性、0 个入参数方法、1 个入参数方法。父类已有能力放在父类 DSL，不在子类重复铺开；有返回值的方法默认也要收口为可继续链下去的主对象，除非该能力天然是查询或明确的终止动作。
- OC 因为 Block 类型繁多，所有可复用 Block typedef 必须集中放入 `JobsBlock` 管理；新增 DSL 前先查 `JobsBlock` 是否已有可复用类型，缺失再补到合适的 `JobsBlock.h`、`ReturnByCertainParametersBlock.h` 或其它既有分类头里，不在 DSL 头文件里私自散落 typedef。
- OC 项目里系统 API DSL 产生的相关 Block 定义全部收进 `JobsBlock`：按返回值和入参签名复用或补齐 typedef，DSL 头文件只引用既有 Block 类型，不本地声明临时 Block。
- `JobsBlock` 是全局 Block 服务，不只服务 DSL。整理 `JobsBlock` / `ReturnByCertainParametersBlock.h` 时，优先按返回值相同归为一组，同组第一行用 `/// 返回类型` 标注；`#pragma mark ——` 只写大类名，不写 `DSL` 字样。遇到外源 Pod 的 Block 定义，大类名写 Pod 名，例如 `#pragma mark —— ReactiveObjC`，再用 `/// RACSignal`、`/// RACDisposable` 这类返回值标注细分。
- 判断 Block 是否重复时，只看返回类型和入参类型；如果两个 typedef 的返回类型和入参类型完全一致，只是 Block 名不同，它们就是同一个 Block。新增调用优先复用现有 typedef；历史兼容名需要保留时，用 `typedef 已有Block名 兼容Block名;` 做别名，不再重复写一遍 `(^BlockName)(...)` 签名。
- `JobsBlock` 里的 Block 类型命名一律把 `Return` 缩写成 `Ret`，例如 `JobsReturnIDByAppLanguageBlock` 必须改成 `JobsRetIDByAppLanguageBlock`。修改 typedef 名后必须全局搜索并同步替换所有调用、属性、方法签名和文档引用；不要只改 `JobsBlock.h`。
- 默认不要新定义 Block。确实缺失时，先全局查 `JobsBlock` 现有类型和别名，确认没有同签名可复用项后，再补到对应返回值分组下，并同步检查公开头 import、podspec 依赖和 README。
- 新增 OC DSL 时要同时考虑公开头、podspec 依赖、README 和调用方 import 边界；`JobsOCDSL` / `JobsModelDSL` 负责链式分类，`JobsBlock` 负责 Block 类型，`JobsMake` 负责创建入口，职责不能混写。
- OC 链式 DSL 的 Block 必须返回可继续链下去的对象；除明确的终止动作外，不写只执行副作用却返回 `void` 的 DSL。Block typedef 优先返回 `__kindof 当前类 * _Nullable` 或主对象类型，方法实现里设置完属性后必须 `return self;`，否则点语法链会在这一节断掉。
- OC / Swift 两侧面对同一个 Apple API 或同一个 Jobs 自建模型语义时，应尽量保持 DSL 名称、参数语义、调用顺序平行；发现一侧缺失时，优先补齐缺失侧，而不是在业务代码里回退到裸赋值。
- 对“中心对象”配置时，优先围绕一个主接收者一路链式调用。需要配置子对象时，优先提供 `byXxxBlock(...)` 这类回调 DSL，让回调内部配置子对象后继续返回主对象，避免主链被 `object.child.xxx` 打断。
- “一链到底”是 Jobs DSL 改造的终结标准：在一个 `jobsMakeXxx`、懒加载 getter 或配置闭包里，主对象变量名应尽量只作为链式起点出现一次，例如 `label.byText(...).byFont(...).addOn(...).byTop(...)`；后续不再散落 `label.xxx = ...`、`label.method(...)` 或第二段 `label.byXxx(...)`。
- 父子类 DSL 调用顺序按 `1.10.1` 执行；如果父类 DSL 会导致返回类型降级，应补充能返回主对象的 block DSL 或当前层 DSL，而不是拆成第二个接收者调用。
- 在本地 Pod 里写 `UITableView`、`UIButton`、`UITextField`、`UILabel` 等 JobsOCDSL 链时，编译通过不是唯一目标，还要检查链条类型是否中途被父类 DSL 降级。例如 `UITableView` 先调 `bySeparatorStyle`、`byDelegate`、`byDataSource`、`byShowsVerticalScrollIndicator` 等本层 / `UIScrollView` 层能力，再调 `byBgColor`、`addOn`、`byAdd` 等 `UIView` 层能力；不要把父类 DSL 插在中间导致后续子类 DSL 失效。
- 写 DSL 示例、Xcode 代码片段和工程配置文档时，点语法以行为最小单位提行书写，方便按行删除或注释。跟在某一行 DSL 后面的解释统一用两根双斜杠 `//`；单独成行的段落说明统一用三根双斜杠 `///`。
- 写 Objective-C 代码、DSL 示例、懒加载 getter 或常见 UI 配置前，先核对实际封装 API，再查看 `~/Library/Developer/Xcode/UserData/CodeSnippets` 下是否已有可复用的 Xcode 代码块；代码块未过时时，优先沿用其命名、占位符和链式组织方式。
- 如果本轮更新了 OC 侧封装、DSL、JobsMake、Block typedef 或固定写法，必须同步检查并反哺 `~/Library/Developer/Xcode/UserData/CodeSnippets` 里的相关 `.codesnippet`，让代码块示例跟真实 API 保持一致；不要让片段继续传播旧封装、旧命名或散落赋值写法。
- `~/Library/Developer/Xcode/UserData/CodeSnippets` 里的 OC 代码片段默认采用“全暴露写法”：常用配置、事件、装配、约束和兼容分支尽量完整列出，让使用者按需求删除或注释，不让使用者临场补 API。片段必须优先传播 Jobs 封装、JobsMake、JobsOCDSL、JobsModelDSL 和聚合头边界，不能为了示例短而退回裸系统 API。
- 每次完善或纠错 OC 代码片段后，必须按同一写法反扫 OC 新工程和老工程应用层，重点查 `rowHeight =`、`contentInset =`、`contentInsetAdjustmentBehavior =`、`backgroundColor =`、`delegate =`、`dataSource =` 等已有 DSL 覆盖的裸赋值。命中 Jobs 自己维护的主工程或本地 Pod 代码时改成链式；外援 `Pods/`、`ManualByOCPods@Pods/` 和确认为第三方源码的目录不处理。
- DSL 示例颗粒度必须细：一个属性、一个状态、一个事件、一个装配动作分别独立成行，不把标题、颜色、字体、图片、内边距等多个意图合并到一行。若同一能力同时存在单参数和二参数写法，默认首选单参数写法；二参数写法只在确实需要表达 `UIControlStateSelected`、`UIControlStateDisabled`、`UIControlStateHighlighted` 等非默认状态差异时使用。

#### 1.10.1、`JobsOCDSL` 链式调用顺序

- [**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) 侧新增或迁移 `JobsOCDSL` 链式方法时，公共属性只放在父类 DSL，子类特有属性只放在子类 DSL，不要为了调用方便在子类重复定义父类能力。
- 调用链必须优先调用本层类型 DSL，再调用父类 DSL。例如 `UILabel` 先调用 `byText`、`byFont`、`byTextAlignment`、`byNumberOfLines`，最后再调用 `UIView` 层的 `byBgColor`、`byCornerRadius` 或 [**Masonry**](https://github.com/SnapKit/Masonry) 层的 `byAddTo`、`byMakeConstraints`、`byUpdateConstraints`、`byRemakeConstraints`。
- 原因是父类 DSL 返回值通常会收口成 `UIView` / 父类类型；如果先调父类 DSL，后面就可能丢失 `UILabel`、`UIButton`、`UITextField` 等子类本层的点语法能力。
- 对齐 [**Swift**](https://www.swift.org/) 项目里的 [**SnapKit**](https://github.com/SnapKit/SnapKit) DSL 时，OC 侧使用 [**Masonry**](https://github.com/SnapKit/Masonry) 在 `JobsOCDSL/Core/ThirdParty/Masonry` 下补公共链式入口。旧 Pod 私有的 `byAdd`、`setMasonryBy`、网格算法、动画算法不要直接搬进公共 DSL，除非先拆掉业务和历史耦合。

  ```objc
  UILabel *label = jobsMakeLabel(^(__kindof UILabel * _Nullable label) {
      label
          .byText(@"Demo")
          .byFont(UIFontSystemFontOfSize(16))
          .byTextAlignment(NSTextAlignmentCenter)
          .byNumberOfLines(1)
          .byAddTo(self.view, ^(MASConstraintMaker *make) {
              make.center.equalTo(self.view);
              make.size.mas_equalTo(CGSizeMake(JobsWidth(200), JobsWidth(20)));
          });
  });
  ```

#### 1.10.2、`JobsMake` + `JobsOCDSL` UI 创建公约

- UI 创建统一优先使用真实归属下的 `jobsMakeXXX` 形成创建 Block：`JobsMakes@Pods/JobsMakes.h` 提供 `jobsMakeView`、`jobsMakeLabel`、`jobsMakeImageView`、`jobsMakeTextView`、`jobsMakeTextField`、`jobsMakeCollectionView`、`jobsMakeScrollView`、`jobsMakeStackView`、`jobsMakeSwitch`、`jobsMakeSlider`、`jobsMakeProgressView`、`jobsMakeSegmentedControl`、`jobsMakeContextualAction`、`jobsMakeSwipeActionsConfiguration` 等；按钮的 `jobsMakeButton` 与表格的 `jobsMakeTableViewByPlain/Grouped/InsetGrouped` 当前由 `JobsByOCPods` 对应分类提供。不要因为名字都以 `jobsMake` 开头就误判所属 Pod。创建入口只负责创建对象和提供闭包，不在里面扩展业务配置。
- 业务配置对象的工厂留在业务能力自己的 Pod：`jobsMakeOCKeyboardConfig` 归 `JobsOCKeyboardMgr` 的 `JobsOCKeyboardConfig` 公共头导出，`JobsMakes` 不得为它反向依赖 `JobsOCKeyboardMgr`。发现 `基础 DSL -> JobsMakes -> 业务 Pod -> 基础 DSL` 这类环时，优先把工厂迁回模型 / 业务 Pod 的真实归属并更新调用方直接依赖，不以搜索路径或暂留裸 API 掩盖循环。
- UIButton 常态标题、标题色、字体、图片、背景图、背景色、圆角和图文间距优先使用 `jobsResetBtnTitle`、`jobsResetBtnTitleCor`、`jobsResetBtnTitleFont`、`jobsResetBtnImage`、`jobsResetBtnBgImage`、`jobsResetBtnBgCor`、`jobsResetBtnCornerRadiusValue`、`jobsResetImagePlacement_Padding`，让新旧管线在封装内部收口。高亮、选中、禁用状态确实需要不同资源时，使用当前实现已提供的 `highlightedStateImageBy(...)`、`selectedStateImageBy(...)`、`disabledStateImageBy(...)` 等 state-specific Jobs API。任意状态及 `UIControlStateSelected | UIControlStateHighlighted` 这类组合态，按资源类型使用 `titleForStateBy`、`attributedTitleForStateBy`、`titleColorForStateBy`、`titleShadowColorForStateBy`、`imageForStateBy`、`backgroundImageForStateBy`、`preferredSymbolConfigurationForStateBy`；复制 / 查询状态资源时使用对应 `titleByState`、`attributedTitleByState`、`titleColorByState`、`titleShadowColorByState`、`imageByState`、`backgroundImageByState`、`preferredSymbolConfigurationByState`，不用常态 API 抹平状态语义，也不退回系统 setter / getter。
- `UISegmentedControl` 创建走 `jobsMakeSegmentedControl(items, block)`，写入选中项走 `bySelectedSegmentIndex(...)`，读取走 `jobs_selectedSegmentIndex`；`UISwitch` 写入 / 读取状态使用 `byOn(...)` / `jobs_isOn`；Auto Layout 开关使用 `UIView.byTranslatesAutoresizingMaskIntoConstraints(...)`。`UIStackView`、`UISwitch`、`UIContextualAction`、`UISwipeActionsConfiguration` 分别使用当前类型 DSL，不再在上层散落系统属性赋值。
- UI 子视图默认使用懒加载 getter 创建和配置。不要在 `setupSubviews`、`viewDidLoad`、`init` 或某个大方法里连续 `UIView.new` / `UILabel.new` / `UIImageView.new` / `UITableView alloc init...` 再散落赋值、添加和约束。`setupSubviews` 只负责触发懒加载、添加层级、部署约束或做极少量编排。
- 懒加载 getter 内部必须用 `JobsMake` + `JobsOCDSL` / `JobsModelDSL` 收口：创建、基础属性、事件、进入父视图、Masonry 约束通过链式写法完成。当前类型缺 DSL 时先补封装，不回退到 `_view = UIView.new; _view.xxx = ...; [parent addSubview:_view];` 这种散落写法。
- 需要保存约束对象时，可以在懒加载 getter 的 `byAdd` / `byOn` / `mas_makeConstraints` block 中赋值给 ivar，例如保存高度约束；但对象本身仍应由 getter 负责创建，不把整棵 UI 树塞进一个方法。
- `JobsMake` 的 Block 内部，属性赋值使用 `JobsOCDSL` / `JobsModelDSL` 点语法链式配置；不要回退成散落的 `label.text = ...`、`view.backgroundColor = ...`。目标属性没有 DSL 时先在属性所属类型补齐，不在调用方留“临时裸写法”。
- UI 装配顺序固定为：先当前类本层 DSL，再父类 DSL，再进入 `UIView+DSL` / `Masonry+DSL` 的装配入口。当前 `UIView+MasonryDSL` 的 `byAddTo(superview, makeBlock)` 是“加父视图 + 首次约束”的组合入口；如果后续拆成独立 `UIView+DSL` 加父视图入口，也必须保证加载到父视图早于 [**Masonry**](https://github.com/SnapKit/Masonry) 约束。
- 能拆开的动作就拆开表达：优先写 `addOn(...).byAdd(...)`，把“进父视图”和“布约束”作为两个明确步骤；`byAddTo(...)` 只保留兼容，不作为默认新增写法。
- 如果某些效果依赖真实 `frame`，例如渐变层、圆角路径、局部切角、阴影路径、动画初始位置等，可以放在 `byAddTo` + [**Masonry**](https://github.com/SnapKit/Masonry) + `layoutIfNeeded` 之后执行；因此“加父视图和约束”通常靠后，但不一定是整个链条的最后一步。
- 只要当前类型已经有 DSL，就不要回退成裸赋值写法；例如 `layer.path = ...`、`borderLayer.strokeColor = ...`、`label.font = ...` 这类语句，在对应层已经有 `byPath(...)`、`byStrokeColor(...)`、`byFont(...)` 时，必须改成链式调用。缺 DSL 就补到属性所属层，不把子类属性错误地下沉到父类 DSL。
- 链式 Block 内部不要夹无意义空行；同一段配置连续写完，除非有明确语义分组，否则不要靠空行制造视觉停顿。
- `UIView+DSL` 负责“进入父视图”这类视图动作，`Masonry+DSL` 负责“部署约束”这类布局动作。二者职责不要混写：不要在普通属性 DSL 里偷偷添加父视图，也不要在 [**Masonry**](https://github.com/SnapKit/Masonry) DSL 里写业务属性。
- `UITableView` / `UICollectionView` 后续免协议 Block 化封装要对照 [**Swift**](https://www.swift.org/) 侧 `JobsSwiftDSL`：优先支持 `byTarget`、`numberOfRowsInSection` / `numberOfItemsInSection`、`cellForRowAt` / `cellForItemAt`、`didSelect...` 等常用入口；协议代理仍可保留，Block 配置作为常用页面的轻量写法。
- 写文档和示例时，必须体现这个统一模型：`JobsMake` 创建对象，`JobsOCDSL` / `JobsModelDSL` 配属性，`UIView+DSL` 添加父视图，[**Masonry**](https://github.com/SnapKit/Masonry) DSL 部署约束，frame 依赖效果在约束刷新之后处理。

#### 1.10.3、Masonry 无警告约束与临时布局阶段

- 新写或修改 UI 后，必须检查控制台 `Unable to simultaneously satisfy constraints`、`UIView-Encapsulated-Layout-*` 和 `UITableViewAlertForLayoutOutsideViewHierarchy`。按日志里的视图类型、约束地址和创建代码定位来源；禁止删除已成立的业务约束、吞日志或用异常捕获伪装无警告。
- `UITableViewCell` / `UICollectionViewCell` 测量时可能临时获得 `44` 或 `0` 的系统封装高度。固定头部、上下边距、折叠内容等只在真实行高下成立时，保留原数值，把其中可压缩的一条写成 `.priority(999)`；真实高度阶段视觉不变，临时阶段不与系统 `UIView-Encapsulated-Layout-Height` 硬冲突。
- 折叠容器禁止同时以必选优先级声明“高度为 `0`”和“上下均有正间距”。保存高度约束并把零高度或非关键底边设为 `999`，展开时只 `setOffset:` / `mas_updateConstraints`，不要重复 `mas_makeConstraints`。
- 视图或 TableView 尚未挂到 `window` 时，不调用 `layoutIfNeeded`、`beginUpdates/endUpdates` 或仅为刷新主题执行 `reloadData`。初始化只准备数据；强制布局用 `self.window` / `view.window` 守卫，或延后到 `viewDidAppear:` / `didMoveToWindow`。
- 首次创建用 `mas_makeConstraints` / `byAdd`，仅常量变化用保存约束或 `mas_updateConstraints`，结构变化才用 `mas_remakeConstraints`。禁止在 cell 复用、配置和 `layoutSubviews` 中重复叠加同义约束。
- 导航控制器、TabBar 子控制器和 titleView 在根窗口仍为 `0×0` 时，不主动触发布局。先完成 `window.rootViewController` 与 `makeKeyAndVisible`，再刷新依赖真实宽高、安全区或导航栏边距的 UI。

  ```objc
  _titleLab = jobsMakeLabel(^(__kindof UILabel * _Nullable label) {
      label
          .byText(@"标题")
          .byFont(UIFontWeightBoldSize(16))
          .byTextAlignment(NSTextAlignmentCenter)
          .byNumberOfLines(1)
          .byBgColor(JobsClearColor)
          .byAddTo(self.contentView, ^(MASConstraintMaker *make) {
              make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(8, 12, 8, 12));
          });
  });
  ```

#### 1.10.3、图标资源规则

- OC 项目中需要用到 UI 图标时，优先复用项目已有图标库、命名和视觉风格；图标可使用 SF Symbols 等系统图标，也可来自 [**iconfont**](https://www.iconfont.cn/)，不随手使用来源不明的图片素材。
- OC 新、老项目的 Demo 入口页面中，每个 cell 前的图标必须与当前入口内容及功能语义贴合，并保证同一页面内不重复；来自 [**iconfont**](https://www.iconfont.cn/) 的图标必须下载到本地并放入当前工程实际使用的 `*.xcassets`，禁止通过 URL 或其它方式远程引用。
- 新图标落地时，按当前项目资源体系放入 `Assets.xcassets`、自建 Pod 的 `Resource` / resource bundle 或既有图标目录，并同步 Xcode 文件引用、podspec 资源声明和 README 资源说明。
- 如果采用字体图标方式集成，要记录并统一维护图标名称、unicode / class 信息；业务代码里不要散落硬编码 codepoint，优先通过统一常量、枚举、模型或封装入口引用。

### 1.11、`*.h` 头文件 `#import` 排序

- 每次新写、修改或批量整理 OC 头文件导入区，都必须同时全文扫描 OC 新项目和老项目中 Jobs 自己维护的 `*.h`；不只修用户点名文件，也不只扫当前子 Pod。继续排除 `Pods/`、`JobsByPods/ManualByOCPods@Pods/`、生成目录和确认的外援第三方源码。
- [**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) 头文件顶部先写一般性 `#import`，再写双通道保护性 `#if __has_include(...)`。一般性写法和双通道保护性写法之间保留一个空行。
- 一般性 `#import` 优先写系统 / Apple / Darwin / 底层头文件，再写本文件直接依赖的普通头文件；越靠近底层越靠上，例如 ObjC runtime / message、C 系统库、`CoreFoundation`、`Foundation`、`UIKit`、`WebKit`、`AVFoundation` 等系统头按底层到上层排列。
- Jobs 自己写的代码里，系统 / Apple / Darwin / ObjC runtime 头文件必须写在对应同名 `*.h` 文件的一般性 import 区域，`*.m` / `*.mm` 不单独导入。不限于 `#import <objc/runtime.h>`：例如 `<objc/message.h>`、`<Foundation/Foundation.h>`、`<UIKit/UIKit.h>`、`<WebKit/WebKit.h>`、`<AVFoundation/AVFoundation.h>`、`<AudioToolbox/AudioToolbox.h>`、`<Photos/Photos.h>`、`<Security/Security.h>`、`<CommonCrypto/CommonCrypto.h>`、`<os/lock.h>`、`<pthread.h>`、`<sys/sysctl.h>`、`<stdint.h>`、`<ctype.h>` 等都按这条执行。即使只有实现文件里调用相关 API，也要由同名头文件统一承接。
- 如果已经写了 `#import <UIKit/UIKit.h>`，则同一个 import 区域不再重复写 `#import <Foundation/Foundation.h>`，因为 `UIKit` 已经包含 `Foundation`。
- 把导入区按“普通单个 `#import` ”和“完整双通道保护块”视为相邻导入单元：普通↔普通之间不留空行；只要相邻两个单元中任意一个是双通道保护块，两者之间必须且只能保留一行空行。这覆盖普通↔双通道、双通道↔普通、双通道↔双通道三种组合；双通道块内部四段结构仍紧凑连写，不插入空行。
- `#import` 导入区和下面的正文内容区之间必须保留一行空行。正文内容区包括 `NS_ASSUME_NONNULL_BEGIN`、`@interface`、`@implementation`、`@protocol`、`@class`、`typedef`、`NS_INLINE`、`static`、`#pragma` 等；例如 `#import "DefineProperty.h"` 后面不能紧贴 `NS_ASSUME_NONNULL_BEGIN`，必须空一行。
- 双通道保护性区域先写外源性 Pod，再写内源性 Pod。外源性 Pod 指 OC 项目 `Pods/` 目录下的模块；内源性 Pod 指 OC 项目 `JobsByPods/` 下除 `ManualByOCPods@Pods/` 以外的模块。
- 内源性 Pod 的双通道保护性写法排序：`JobsOCProtocols` 靠前，中间写其他内源 Pod，`JobsBlock` 和 `JobsOCDefs` 靠后；其中 `JobsOCDefs` 通常作为宏定义兜底放在最后。
- 跨模块保护性 import 承接 `1.4` 的边界规则：公开依赖写同名 `*.h`，外部 Pod 固定导入聚合头，例如 `#import <ZFPlayer/ZFPlayer.h>`；不要在双通道块里拆成多个内部子头。
- Jobs 自己写的 `*.m` / `*.mm` 不允许出现 `#if __has_include(...)` / `#elif __has_include(...)` 包住 `#import`、`#define HAS_*` 或 fallback import 的保护性块；这些块必须整体移到同名 `*.h`。实现文件如果还需要可选能力判断，只能使用同名头文件定义好的 `HAS_*` 宏。
- Jobs 自己写的普通业务 `*.m` / `*.mm` 顶部默认只保留自身同名头文件；除当前 Pod 内部确需引用自身 `Support` 私有支援文件外，其它类、Cell、Model、聚合头、DSL 头和跨模块头都应上提到同名 `*.h`。
- 批量改完 OC import 后，必须全文扫描 Jobs 自维护范围内的 `.m` / `.mm`：`rg -n --glob '*.m' --glob '*.mm' --glob '!Pods/**' --glob '!JobsByPods/ManualByOCPods@Pods/**' "__has_include" .`。只要实现文件命中，就继续上提到同名头文件：保护性 import 整体迁移；可选能力判断改成同名头文件定义 `HAS_*` 宏后由 `.m` 使用宏判断。目标是 Jobs 自维护 `.m` / `.mm` 不直接出现 `__has_include`。
- 批量改完 OC 系统头 import 后，必须全文扫描 Jobs 自维护范围内的 `.m` / `.mm`：`rg -n --glob '*.m' --glob '*.mm' --glob '!Pods/**' --glob '!JobsByPods/ManualByOCPods@Pods/**' '^#import <(objc/|Foundation/|UIKit/|WebKit/|AVFoundation/|AudioToolbox/|Photos/|Security/|CommonCrypto/|Core[A-Za-z]+/|QuartzCore/|ImageIO/|MobileCoreServices/|UniformTypeIdentifiers/|os/|sys/|libkern/|XCTest/|pthread\\.h|stdint\\.h|stdio\\.h|stdlib\\.h|string\\.h|ctype\\.h)' .`。只要命中 Jobs 自己写的实现文件，就把系统头上提到同名 `*.h`；如果没有同名头或该文件是明确第三方源码，必须在最终说明中标出原因。
- 双通道保护性写法固定保持四段结构，不要拆散：

  ```objc
  #if __has_include(<MJRefresh/MJRefresh.h>)
  #import <MJRefresh/MJRefresh.h>
  #else
  #import "MJRefresh.h"
  #endif
  ```

- 例如 `JobsModel` 和 `JobsBlock` 这两个模块之间，必须写成下面这样：

  ```objc
  #if __has_include(<JobsModel/JobsModel.h>)
  #import <JobsModel/JobsModel.h>
  #else
  #import "JobsModel.h"
  #endif

  #if __has_include(<JobsBlock/JobsBlock.h>)
  #import <JobsBlock/JobsBlock.h>
  #else
  #import "JobsBlock.h"
  #endif
  ```

### 1.12、Xcode 工程里的 Markdown 文档引用

- [**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) 工程范围内的 Markdown 文档统一命名为 `README.md`。遇到历史遗留的 `xxx.md` 文件时，改为 `xxx.md/README.md` 这种“同名目录包裹 README”的结构，避免同一目录下多个说明文件互相抢名。
- `README.md` 只作为文档引用存在，可以在 [**Xcode**](https://developer.apple.com/xcode) 左侧导航中展示，但不得加入 `Sources`、`Resources`、`Copy Files`、`Headers` 等任何 Build Phase，不进入编译、打包或资源拷贝环节。
- 批量整理 Markdown 后必须同步检查 `*.xcodeproj/project.pbxproj`：`PBXFileReference` 应指向新的 `README.md` 路径；如果发现 `*.md in Sources`、`*.md in Resources`、`*.md in Copy Files` 或 `*.md in Headers`，必须移除对应 `PBXBuildFile` 和 Build Phase 条目，只保留文件引用。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
