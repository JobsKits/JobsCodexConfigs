---
name: jobs-objective-c-pods
description: 当任务涉及 Objective-C、本地 Pods、Core/Support、头文件引用、Pod 拆分、JobsDefineProperty、JobsOCDSL、JobsModelDSL、JobsBlock、JobsMake、import 排序或 Xcode Markdown 引用时使用。
---

# Jobs Objective-C 与本地 Pods 工程规范

> 本技能由 `💻JobsCodexConfigs/AGENTS.md` 拆分而来，保留原有 Jobs 工作规范。只有当前任务命中本技能描述时才加载本文件，避免把所有细则长期塞进全局上下文。

## 六、[**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) / 本地 Pods 工程规范 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 6.1、工程背景与目录边界

- 本规范默认服务 Jobs 的 OC 工程，尤其是把原工程里的本地代码逐步提取为本地管理 Pods 的场景。
- Swift 侧的 iOS 项目固定指 `/Users/jobs/Documents/Github/JobsBaseConfig/JobsBaseConfig@JobsSwiftBaseConfigDemo`。
- OC 侧的新项目固定指 `/Users/jobs/Documents/Github/JobsOCBaseConfigDemo@ByPods`。
- OC 侧的老项目固定指 `/Users/jobs/Documents/Github/JobsBaseConfig/JobsBaseConfig@JobsOCBaseConfigDemo`。
- OC 新项目里“Jobs 自己写的代码”定义为：除 `Pods/` 及其下辖、`JobsByPods/ManualByOCPods@Pods/` 及其下辖之外的全部代码。
- 所有本地管理的 Pod 默认位于项目根目录 `JobsByPods` 文件夹下，每个 Pod 文件夹命名统一为 `Pod名@Pods`。
- 外源性 Pod 本地化后，统一放入 `JobsByPods/ManualByOCPods@Pods` 管辖。第三方来源信息要保留，只做本地托管适配，不抹掉上游痕迹。
- `JobsByOCPods` 是最初提取出来的本地 Pod，也是后续本地 Pods 分离时的源头参照。遇到缺文件、缺宏、缺分类、缺辅助类时，优先回到 `JobsByOCPods` 找源头，再迁移到目标 Pod 的合适位置。
- 工程最初能完整编译通过的前提，是尚未把部分本地写法提取成多个本地 Pod。拆分后，每个 Pod 实际上成为独立工程，只是通过同一个 `xcworkspace` 协同管理，因此编译器会提高跨域访问门槛，暴露头文件、模块化、依赖边界和循环引用问题。
- 处理编译错误时，不要只追求“先编过”。要判断错误是不是由本地 Pod 化后的边界变化引起：头文件暴露层级、`Core` / `Support` 归属、podspec 依赖、聚合头、`HEADER_SEARCH_PATHS`、循环依赖，都要一起看。

### 6.2、`Core` / `Support` 文件夹职责

- 每个本地 Pod 默认必须有 `Core` 文件夹；`Support` 文件夹按需存在，不强制创建空目录。
- `Core` 里放准备随着这个 Pod 向外暴露的核心能力。`Core` 代码的头文件通常进入 `public_header_files`，是使用方能看到的 API 边界。
- `Support` 里放辅助 `Core` 的实现细节、兼容代码、内部分类、桥接文件、局部宏和非公开工具。`Support` 不是为了给外部随便引用，而是为了减少 Pod 之间的横向耦合。
- 某个 Pod 缺文件时，最合理路径不是立刻新增跨 Pod 引用，而是去源头 `JobsByOCPods` 寻找，迁移到当前 Pod 的 `Support` 文件夹下，并按既定目录格式放入。
- 能放进当前 Pod `Support` 解决的，不要轻易加新的 Pod 依赖。只有该能力确实属于独立公共能力、多个 Pod 都应该复用时，才考虑拆成独立 Pod 或依赖已有 Pod。
- `Core` / `Support` 的真实磁盘目录结构必须能在 [**Xcode**](https://developer.apple.com/xcode) / Pods 工程里显示出来。新增、删除、移动目录后，通过 `JobsPodspecKit.rb` 动态映射，`pod install` 后应反映真实目录结构。

### 6.3、头文件引用边界

- `Core` 文件夹下的文件用到 `Core` 文件夹下的文件，引用写在 `*.h`。这是公开 API 边界内部的正常暴露。
- `Support` 文件夹下的文件用到 `Support` 文件夹下的文件，引用写在 `*.h`。这是内部辅助层之间的正常依赖。
- `Core` 文件夹下的文件用到 `Support` 文件夹下的文件，引用写在 `*.m`，避免把内部实现细节泄露到公开头文件。
- 用到其他 Pod 时，一律优先保护性写法 + 聚合头文件，避免本地路径、Pods Header 映射和模块化状态不一致导致编译失败。
- 除 `Pods/` 及其下辖、`JobsByPods/ManualByOCPods@Pods/` 及其下辖之外，全局引用其他 Pod 时都应用同一规则：优先导入该 Pod 的聚合头，不直接导入子头、私有头或某个特别文件。
- 其他 Pod 的聚合头双通道保护性写法，优先写在当前模块的 `*.h` 文件里；因为 `*.h` 会参与外部编译，可以把公开 API 需要的依赖边界同步暴露出去。只有放在 `*.h` 会导致编译报错、循环依赖，或该依赖确实只是 `*.m` 内部实现细节时，才退回写在 `*.m`。
- 对 `JobsOCDSL`、`JobsMakes`、`JobsModelDSL`、`JobsBlock`、`JobsOCDefs` 这类聚合头，默认按“能上提到同名 `*.h` 就不上留在 `*.m`”执行；不要因为当前实现文件里用了点语法或链式调用，就把聚合头偷放在 `*.m`。只有确认该依赖纯属实现细节，或放进 `*.h` 会直接引发循环依赖、公开边界污染时，才允许留在 `*.m`，并且要带着这个判断去改，不是图省事。
- 头文件只引入当前 `*.h` 真实暴露类型、协议、宏或声明所需要的模块，不为了 `*.m` 内部实现、链式 DSL 便利或历史迁移跨模块扩大 import。比如头文件实际只暴露 `JobsModel` 里的 model，就继续引 `JobsModel`；只有头文件 API 直接使用 `JobsModelDSL` 的链式类型、Block 或方法声明时，才引 `JobsModelDSL`。
- 如果 `*.m` 需要某个 DSL 能力，而 `*.h` 没有暴露这个 DSL 类型，优先把 DSL 头文件放到 `*.m`；不要把实现细节通过公开头传染给外部模块。
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
- 头文件放置的核心判断：公开 API 所需的最小依赖可以进入 `*.h`；实现细节、兼容分支、内部分类、只在方法体里使用的类型，优先留在 `*.m`。

### 6.4、本地 Pod 拆分策略

- 拆 Pod 前先确认职责边界：这个能力是公共基础能力、业务 UI、工具分类、模型、宏定义、资源包，还是某个 Pod 的内部辅助实现。职责没分清，不要急着建新 Pod。
- 从 `JobsByOCPods` 分离能力时，优先保持原始文件命名、注释风格和调用方式，先完成边界收口，再考虑小范围整理。
- 新 Pod 目录必须使用 `Pod名@Pods`，内部至少包含 `Core`、`Pod名.podspec`、必要时包含 `Support`、`JobsPodspecKit.rb`、`README.md`、入口头 `Pod名.h`。
- 能用 `Support` 消化的跨域访问问题，优先迁移到当前 Pod `Support`；确实属于可复用公共能力时，才新增 Pod 依赖。
- 对第三方库做 Jobs 风格补充时，优先独立成本地管理的 `Extra` Pod，并以 `Extra` 结尾，例如 `BRPickerViewExtra`、`GKCustomNavigationBarExtra`、`HTMLDocumentExtra`。这些补充不直接改外援源码，优先放入对应 `Extra@Pods/Core`。
- `Extra` Pod 里如果发现继承自 `NSObject`、实质承担配置 / model 职责的第三方类或本地适配类，默认做成 `类名+DSL.h/.m` 的形式并入对应 `Extra` Pod 的 `Core`。如果 `Core` 下文件不止一对 `*.h/*.m`，每组文件优先用各自名字命名的文件夹包裹管理，例如 `Core/BRPickerStyle/BRPickerStyle+DSL.h`。
- 一个文件只办一件事。遇到历史代码在 `类名+Category.h/.m` 里顺手定义主类、兼容空类、记录类、配置类等独立类型时，必须拆到独立的 `类名.h/.m` 文件；category 文件只保留 category 职责。为防止旧代码或外部库重复定义，兼容类声明和空实现默认用 `#ifndef` 宏保护。
- 批量修改后，如果用户指出一个具体文件的问题，默认按同一套批量规则做全局回归扫描。只要该问题可能由统一脚本、统一替换、统一 import 规则造成，就不能只修被点名文件，要在同一覆盖范围内找同类问题并同步修正。
- 每次新增、删除或调整 Pod 依赖，都要同步检查直接依赖和第二层以下间接依赖。不要只看当前 podspec 里写了什么，还要看它依赖的 Pod 又依赖了谁。
- 严禁用“互相依赖”解决编译问题。出现循环依赖时，要把公共部分下沉到更底层 Pod，或把内部实现移动到 `Support`，而不是继续堆 `dependency`。

### 6.4.1、`JobsDefineProperty.h` 属性宏覆盖

- `JobsOCDefs` 是最底层定义 Pod，`JobsDefineProperty.h` 里对系统冗长的 `@property` 做了 `Prop()` / `Prop_strong()` / `Prop_weak()` / `Prop_assign()` / `Prop_copy()` / `Prop_retain()` 简短定义。Jobs 自己维护的代码默认使用这些宏，不再新增系统冗长写法。
- 全局覆盖范围：项目主工程、非 `Pods` 文件夹及其下辖文件、`JobsByPods` 中除 `ManualByOCPods@Pods` 之外的本地管理 Pod。外援 Pod、`Pods/` 生成物、`JobsByPods/ManualByOCPods@Pods/` 下手动托管的第三方源码不做覆盖。用户明确指定旧工程“除了 `Pods` 文件夹下”时，按该工程实际外援边界执行。
- 限定范围内只要出现真实 `@property` 声明，就要替换为属性宏；不只处理 `strong` / `weak` / `assign` / `copy` / `retain`，`readonly`、`readwrite`、`class`、`getter=`、`nullable`、`nonnull` 等属性参数也要并入对应宏参数。属性之间如果没有注释，不保留空行。
- 执行覆盖后要确认使用 `Prop_*()` 的目标头文件直接导入属性宏头，不依赖 `.m`、PCH 或间接包含。新本地 Pod 优先按真实模块导入 `JobsDefineProperty.h` / `JobsOCDefs` 聚合入口；旧主工程如果实际宏头叫 `DefineProperty.h`，就必须写 `#import "DefineProperty.h"`，不要误写成 `JobsDefineProperty.h`。
- 如果某个独立 Pod 因宏不可见编译失败，优先补该 Pod 对 `JobsOCDefs` 的直接依赖和保护性 import，而不是退回系统 `@property` 写法。

### 6.5、Pod README 同步规则

- 每个本地 Pod 都应有自己的 `README.md`，因为每个 Pod 本质上都是相对独立的工程。
- 只要更新 Pod 的 `Core`、`Support`、podspec、依赖、资源、入口头、公开 API，就要同步更新该 Pod 的 `README.md`。
- Pod README 按本文档 `4.4、README 固定内容` 的格式写，至少说明：用途、适用场景、目录结构、`Core` / `Support` 边界、公开能力、内部辅助能力、依赖关系、引用方式、资源说明、验证方式、风险说明。
- README 不要只写口号。它要能帮助后续排查：这个 Pod 为什么存在、哪些文件是公开的、哪些文件只是内部支撑、缺文件时应该回哪里找、修改依赖后要看哪个报告。

### 6.6、依赖报告与循环引用校正

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

### 6.7、`ScriptsByPods` 脚本约定

- `ScriptsByPods` 存放适用于整个当前工程的脚本，其中一部分会挂载到 `pod install` 后自动运行。
- 因为 [**CocoaPods**](https://cocoapods.org/) 本身使用 [**Ruby**](https://www.ruby-lang.org) 生态，Pod 相关脚本优先使用原生 Shell + Ruby。除非确实没法低成本实现，不要引入 [**Python**](https://www.python.org)、Node.js 或其他额外运行环境。
- 能在 Shell 里稳定完成的路径处理、文件扫描、日志输出、交互确认，不要强行换语言。能在 Ruby 里直接读 podspec / Podfile / CocoaPods 上下文的，不要绕远路。
- 脚本仍然遵守本文 `二、MacOS Shell 脚本` 的基座规则：`#!/bin/zsh`、路径变量、彩色日志、README 阻塞、防误触、`main "$@"`、危险操作 `YES` 确认、静态检查。
- OC 项目的 `Podfile.deps` 只维护 `pod` 依赖定义，不直接执行外部脚本；外部脚本统一由 `Podfile` 调用，并且必须具备“脚本不存在就跳过、不影响 `pod install` 主流程”的保护。
- `Podfile` 中所有 `ScriptsByPods`、`.command`、`.sh`、`.rb` 脚本调用，以及 `load` 外部 Ruby 文件，都按可选增强处理：脚本缺失、`chmod +x` 失败、脚本执行失败时只打印告警并返回，不用 `raise` 中断。除非用户明确指定强制门禁，否则依赖报告、CodeGraph 等 post-install 脚本都不能阻塞主流程。

### 6.8、`return self` 收口格式

- [**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) 链式 Block / 初始化收口里，如果最后一行是 `return self;`，且上一行刚好是右括号 `}`，则 `return self;` 不单独成行，必须紧跟在上一行右括号后面写成 `}return self;`。
- 这条规则只应用 Jobs 自己写的代码；外援 Pod 不处理，包括 `Pods/` 目录和 `JobsByPods/ManualByOCPods@Pods/` 目录。

  ```objc
  -(JobsRetMutableParagraphStyleByCGFloatBlock _Nonnull)byDefaultTabInterval {
      @jobs_weakify(self)
      return ^__kindof NSMutableParagraphStyle * (CGFloat v) {
          @jobs_strongify(self)
          if (@available(iOS 7.0, tvOS 9.0, watchOS 2.0, visionOS 1.0, *)) {
              self.defaultTabInterval = v;
          }return self;
      };
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

### 6.8.0、Jobs DSL 总体思想

- Jobs 的 OC / Swift DSL 本质是一套命名和调用思想：用点语法 + 链式语法让对象从创建、配置、事件、装配到布局尽量一路设置下去，减少散落赋值和割裂的中间变量。
- DSL 命名统一使用 `by` + 首字母大写的属性名、单参数方法名或一个参数语义名。例如 `text` 对应 `byText(...)`，`font` 对应 `byFont(...)`，`addSubview:` 这类动作可按既有封装写成 `addOn(...)` / `byAddTo(...)` 等项目内统一语义。
- 遇到 `BOOL` 属性且系统名以 `is` 开头时，DSL 名省略 `is`，例如 `isSelected` 写成 `bySelected(...)`，`isEnabled` 写成 `byEnabled(...)`，保持 Swift / OC 两侧命名平行。
- DSL 覆盖范围不只限于 Apple 原生 API。Jobs 自建 Model、配置对象、业务基础对象也要按同一套思路封装；OC 侧重点体现在 `JobsModel` 的 `JobsModelDSL`，例如 `UIViewModel`、`UITextModel`、`UIButtonModel` 等大 Model / 子 Model 都应支持链式配置。
- OC 因为 Block 类型繁多，所有可复用 Block typedef 必须集中放入 `JobsBlock` 管理；新增 DSL 前先查 `JobsBlock` 是否已有可复用类型，缺失再补到合适的 `JobsBlock.h`、`ReturnByCertainParametersBlock.h` 或其它既有分类头里，不在 DSL 头文件里私自散落 typedef。
- `JobsBlock` 是全局 Block 服务，不只服务 DSL。整理 `JobsBlock` / `ReturnByCertainParametersBlock.h` 时，优先按返回值相同归为一组，同组第一行用 `/// 返回类型` 标注；`#pragma mark ——` 只写大类名，不写 `DSL` 字样。遇到外源 Pod 的 Block 定义，大类名写 Pod 名，例如 `#pragma mark —— ReactiveObjC`，再用 `/// RACSignal`、`/// RACDisposable` 这类返回值标注细分。
- 判断 Block 是否重复时，只看返回类型和入参类型；如果两个 typedef 的返回类型和入参类型完全一致，只是 Block 名不同，它们就是同一个 Block。新增调用优先复用现有 typedef；历史兼容名需要保留时，用 `typedef 已有Block名 兼容Block名;` 做别名，不再重复写一遍 `(^BlockName)(...)` 签名。
- `JobsBlock` 里的 Block 类型命名一律把 `Return` 缩写成 `Ret`，例如 `JobsReturnIDByAppLanguageBlock` 必须改成 `JobsRetIDByAppLanguageBlock`。修改 typedef 名后必须全局搜索并同步替换所有调用、属性、方法签名和文档引用；不要只改 `JobsBlock.h`。
- 默认不要新定义 Block。确实缺失时，先全局查 `JobsBlock` 现有类型和别名，确认没有同签名可复用项后，再补到对应返回值分组下，并同步检查公开头 import、podspec 依赖和 README。
- 新增 OC DSL 时要同时考虑公开头、podspec 依赖、README 和调用方 import 边界；`JobsOCDSL` / `JobsModelDSL` 负责链式分类，`JobsBlock` 负责 Block 类型，`JobsMake` 负责创建入口，职责不能混写。
- OC 链式 DSL 的 Block 必须返回可继续链下去的对象；除明确的终止动作外，不写只执行副作用却返回 `void` 的 DSL。Block typedef 优先返回 `__kindof 当前类 * _Nullable` 或主对象类型，方法实现里设置完属性后必须 `return self;`，否则点语法链会在这一节断掉。
- OC / Swift 两侧面对同一个 Apple API 或同一个 Jobs 自建模型语义时，应尽量保持 DSL 名称、参数语义、调用顺序平行；发现一侧缺失时，优先补齐缺失侧，而不是在业务代码里回退到裸赋值。
- 对“中心对象”配置时，优先围绕一个主接收者一路链式调用。需要配置子对象时，优先提供 `byXxxBlock(...)` 这类回调 DSL，让回调内部配置子对象后继续返回主对象，避免主链被 `object.child.xxx` 打断。
- “一链到底”是 Jobs DSL 改造的终结标准：在一个 `jobsMakeXxx`、懒加载 getter 或配置闭包里，主对象变量名应尽量只作为链式起点出现一次，例如 `label.byText(...).byFont(...).addOn(...).byTop(...)`；后续不再散落 `label.xxx = ...`、`label.method(...)` 或第二段 `label.byXxx(...)`。
- 当一条链中先调用父类 DSL 会导致返回类型降级时，必须先完成当前类本层 DSL，再进入父类 DSL；如果后续仍需要回到子类能力，应补充能返回主对象的 block DSL 或当前层 DSL，而不是拆成第二个接收者调用。
- 写 DSL 示例、Xcode 代码片段和工程配置文档时，点语法以行为最小单位提行书写，方便按行删除或注释。跟在某一行 DSL 后面的解释统一用两根双斜杠 `//`；单独成行的段落说明统一用三根双斜杠 `///`。
- DSL 示例颗粒度必须细：一个属性、一个状态、一个事件、一个装配动作分别独立成行，不把标题、颜色、字体、图片、内边距等多个意图合并到一行。若同一能力同时存在单参数和二参数写法，默认首选单参数写法；二参数写法只在确实需要表达 `UIControlStateSelected`、`UIControlStateDisabled`、`UIControlStateHighlighted` 等非默认状态差异时使用。

### 6.8.1、`JobsOCDSL` 链式调用顺序

- [**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) 侧新增或迁移 `JobsOCDSL` 链式方法时，公共属性只放在父类 DSL，子类特有属性只放在子类 DSL，不要为了调用方便在子类重复定义父类能力。
- 调用链必须优先调用本层类型 DSL，再调用父类 DSL。例如 `UILabel` 先调用 `byText`、`byFont`、`byTextAlignment`、`byNumberOfLines`，最后再调用 `UIView` 层的 `byBgColor`、`byCornerRadius` 或 [**Masonry**](https://github.com/SnapKit/Masonry) 层的 `byAddTo`、`byMakeConstraints`、`byUpdateConstraints`、`byRemakeConstraints`。
- 原因是父类 DSL 返回值通常会收口成 `UIView` / 父类类型；如果先调父类 DSL，后面就可能丢失 `UILabel`、`UIButton`、`UITextField` 等子类本层的点语法能力。
- 对齐 [**Swift**](https://www.swift.org/) 项目里的 [**SnapKit**](https://github.com/SnapKit/SnapKit) DSL 时，OC 侧使用 [**Masonry**](https://github.com/SnapKit/Masonry) 在 `JobsOCDSL/Core/ThirdParty/Masonry` 下补公共链式入口。旧 Pod 私有的 `byAdd`、`setMasonryBy`、网格算法、动画算法不要直接搬进公共 DSL，除非先拆掉业务和历史耦合。

  ```objc
  UILabel *label = UILabel.alloc.init
      .byText(@"Demo")
      .byFont([UIFont systemFontOfSize:16])
      .byTextAlignment(NSTextAlignmentCenter)
      .byNumberOfLines(1)
      .byAddTo(self.view, ^(MASConstraintMaker *make) {
          make.center.equalTo(self.view);
          make.size.mas_equalTo(CGSizeMake(JobsWidth(200), JobsWidth(20)));
      });
  ```

### 6.8.2、`JobsMake` + `JobsOCDSL` UI 创建公约

- UI 创建统一优先使用 `JobsMakes@Pods/Core/JobsMakes.h` 里的 `jobsMakeXXX` 形成创建 Block，例如 `jobsMakeLabel`、`jobsMakeButton`、`jobsMakeTextView`、`jobsMakeTextField`、`jobsMakeTableViewByPlain`、`jobsMakeCollectionView`。`JobsMake` 只负责创建对象和提供闭包入口，不在里面扩展业务配置。
- `JobsMake` 的 Block 内部，属性赋值优先使用 `JobsOCDSL` / `JobsModelDSL` 点语法链式配置；不要回退成散落的 `label.text = ...`、`view.backgroundColor = ...`，除非目标属性当前还没有 DSL，或者临时保留旧写法等待补 DSL。
- UI 装配顺序固定为：先当前类本层 DSL，再父类 DSL，再进入 `UIView+DSL` / `Masonry+DSL` 的装配入口。当前 `UIView+MasonryDSL` 的 `byAddTo(superview, makeBlock)` 是“加父视图 + 首次约束”的组合入口；如果后续拆成独立 `UIView+DSL` 加父视图入口，也必须保证加载到父视图早于 [**Masonry**](https://github.com/SnapKit/Masonry) 约束。
- 能拆开的动作就拆开表达：优先写 `addOn(...).byAdd(...)`，把“进父视图”和“布约束”作为两个明确步骤；`byAddTo(...)` 只保留兼容，不作为默认新增写法。
- 如果某些效果依赖真实 `frame`，例如渐变层、圆角路径、局部切角、阴影路径、动画初始位置等，可以放在 `byAddTo` + [**Masonry**](https://github.com/SnapKit/Masonry) + `layoutIfNeeded` 之后执行；因此“加父视图和约束”通常靠后，但不一定是整个链条的最后一步。
- 只要当前类型已经有 DSL，就不要回退成裸赋值写法；例如 `layer.path = ...`、`borderLayer.strokeColor = ...`、`label.font = ...` 这类语句，在对应层已经有 `byPath(...)`、`byStrokeColor(...)`、`byFont(...)` 时，必须改成链式调用。缺 DSL 就补到属性所属层，不把子类属性错误地下沉到父类 DSL。
- 链式 Block 内部不要夹无意义空行；同一段配置连续写完，除非有明确语义分组，否则不要靠空行制造视觉停顿。
- `UIView+DSL` 负责“进入父视图”这类视图动作，`Masonry+DSL` 负责“部署约束”这类布局动作。二者职责不要混写：不要在普通属性 DSL 里偷偷添加父视图，也不要在 [**Masonry**](https://github.com/SnapKit/Masonry) DSL 里写业务属性。
- `UITableView` / `UICollectionView` 后续免协议 Block 化封装要对照 [**Swift**](https://www.swift.org/) 侧 `JobsSwiftDSL`：优先支持 `byTarget`、`numberOfRowsInSection` / `numberOfItemsInSection`、`cellForRowAt` / `cellForItemAt`、`didSelect...` 等常用入口；协议代理仍可保留，Block 配置作为常用页面的轻量写法。
- 写文档和示例时，必须体现这个统一模型：`JobsMake` 创建对象，`JobsOCDSL` / `JobsModelDSL` 配属性，`UIView+DSL` 添加父视图，[**Masonry**](https://github.com/SnapKit/Masonry) DSL 部署约束，frame 依赖效果在约束刷新之后处理。

  ```objc
  _titleLab = jobsMakeLabel(^(__kindof UILabel * _Nullable label) {
      label
          .byText(@"标题")
          .byFont([UIFont boldSystemFontOfSize:16])
          .byTextAlignment(NSTextAlignmentCenter)
          .byNumberOfLines(1)
          .byBgColor(UIColor.clearColor)
          .byAddTo(self.contentView, ^(MASConstraintMaker *make) {
              make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(8, 12, 8, 12));
          });
  });
  ```

### 6.9、`*.h` 头文件 `#import` 排序

- [**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) 头文件顶部先写一般性 `#import`，再写双通道保护性 `#if __has_include(...)`。一般性写法和双通道保护性写法之间保留一个空行。
- 一般性 `#import` 优先写系统 / 底层头文件，再写本文件直接依赖的普通头文件；越靠近底层越靠上，例如 C / C++ / runtime 相关头文件优先于 `Foundation` / `UIKit`。
- 如果已经写了 `#import <UIKit/UIKit.h>`，则同一个 import 区域不再重复写 `#import <Foundation/Foundation.h>`，因为 `UIKit` 已经包含 `Foundation`。
- 一般性 `#import` 之间不留空行，一行一个；双通道保护性写法之间保留一个空行。不同模块的双通道保护性 `#if __has_include(...)` 块不能紧贴连写，前一个模块的 `#endif` 和后一个模块的 `#if __has_include(...)` 之间必须空一行。
- `#import` 导入区和下面的正文内容区之间必须保留一行空行。正文内容区包括 `NS_ASSUME_NONNULL_BEGIN`、`@interface`、`@implementation`、`@protocol`、`@class`、`typedef`、`NS_INLINE`、`static`、`#pragma` 等；例如 `#import "DefineProperty.h"` 后面不能紧贴 `NS_ASSUME_NONNULL_BEGIN`，必须空一行。
- 双通道保护性区域先写外源性 Pod，再写内源性 Pod。外源性 Pod 指 OC 项目 `Pods/` 目录下的模块；内源性 Pod 指 OC 项目 `JobsByPods/` 下除 `ManualByOCPods@Pods/` 以外的模块。
- 内源性 Pod 的双通道保护性写法排序：`JobsOCProtocols` 靠前，中间写其他内源 Pod，`JobsBlock` 和 `JobsOCDefs` 靠后；其中 `JobsOCDefs` 通常作为宏定义兜底放在最后。
- 双通道保护性 import 如果是为了本模块公开类型、协议、宏或属性声明服务，必须写在同模块 `*.h`；不要把公开头需要的跨模块 import 留在 `*.m`。外部 Pod 已有聚合头时，固定导入聚合头，例如 `#import <ZFPlayer/ZFPlayer.h>`，不要在双通道块里拆成多个内部子头。
- Jobs 自己写的代码里，`*.m` / `*.mm` 文件不允许出现双通道保护性 import；如果实现文件里需要 `#if __has_include(...)` + `#import ...` + `#else` + `#import ...` + `#endif`，必须把这段移到同名 `*.h` 文件，由实现文件通过自身头文件承接依赖。
- 头文件只引入当前头文件已经暴露或直接使用的模块，不为了 `.m` 的实现便利跨模块引入更高层 DSL。例如头文件只用到 `JobsModel` 时，继续导入 `JobsModel`，不要改成 `JobsModelDSL`。
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

### 6.10、Xcode 工程里的 Markdown 文档引用

- [**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) 工程范围内的 Markdown 文档统一命名为 `README.md`。遇到历史遗留的 `xxx.md` 文件时，改为 `xxx.md/README.md` 这种“同名目录包裹 README”的结构，避免同一目录下多个说明文件互相抢名。
- `README.md` 只作为文档引用存在，可以在 [**Xcode**](https://developer.apple.com/xcode) 左侧导航中展示，但不得加入 `Sources`、`Resources`、`Copy Files`、`Headers` 等任何 Build Phase，不进入编译、打包或资源拷贝环节。
- 批量整理 Markdown 后必须同步检查 `*.xcodeproj/project.pbxproj`：`PBXFileReference` 应指向新的 `README.md` 路径；如果发现 `*.md in Sources`、`*.md in Resources`、`*.md in Copy Files` 或 `*.md in Headers`，必须移除对应 `PBXBuildFile` 和 Build Phase 条目，只保留文件引用。
