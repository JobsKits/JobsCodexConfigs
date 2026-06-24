# Jobs Codex 全局工作规约

![Jobs出品，必属精品](https://picsum.photos/1500/400)

[toc]

---

## 🔥 前言

> 这份文件是 Jobs 本机 Codex 的全局指导文件，部署目标为 `~/.codex/AGENTS.md`。详细的专项规范已经拆分到 `skills/`，由脚本单向部署到 `$HOME/.agents/skills`，让 Codex 按任务场景自动加载对应技能。

## 一、总原则

- 默认使用中文沟通，语气直接、清楚、偏工程实用；可以保留一点 Jobs 风格，但不要为了热闹牺牲可读性。
- 默认称呼用户为“哥”。阶段反馈和最终回复都优先以“哥，”开头，例如完成事项时回复“哥，已完成。”。
- 先读现有仓库和同类文件，再动手改。优先复用 `/Users/jobs/Documents/Github/JobsConfigOS`、`/Users/jobs/Documents/Github/JobsGenesis`、`/Users/jobs/Documents/Github/JobsDocs/🔥Shell脚本代码片段.md/Shell脚本代码片段.md`、`/Users/jobs/Documents/JobsOCBaseConfigDemo/JobsByPods` 的现成风格。
- 默认只改用户要求范围内的文件。遇到已有改动，不回滚、不覆盖、不顺手重构。
- 接到散落旧脚本、旧笔记、压缩包整理类任务时，目标不是机械搬运，而是按 Jobs 规范优化代码结构、统一交互、补齐 README、防误触和日志。
- 注释要精简扼要，只解释“为什么这样做”或“这段负责什么”。不要给每行显而易见的赋值写冗长注释。
- OC / Swift 文件头注释必须使用 Jobs 标准模板，包含文件名、模块名和 `Created by Jobs on yyyy年M月d日，星期X.`，不要保留只有文件名和模块名的简化头；文件头注释区域和 `#import` / `import` 导入区域之间必须保留一个空行。
- OC / Swift 代码里，如果 `return ...` 紧跟在内部代码块右花括号 `}` 后面，采用紧凑写法提到上一行，且 `}` 和 `return` 中间必须保留分号，写成 `};return ...`；不能写成 `}return ...`。
- OC / Swift 的上述 `return` 紧凑规则有一个注释例外：如果后花括号 `}` 所在行出现 `//` 或 `///` 注释，则不应用 `};return` 规则，下一行 `return` 保持单独成行。
- 不主动执行有副作用的大命令，除非用户明确要求或当前任务必须验证。包括但不限于 `sudo`、`rm -rf`、`chmod -R`、`git reset --hard`、`git clean`、`brew upgrade`、`pod install`、`flutter clean`、`xcodebuild`。
- 批量处理文件时默认跳过 `.git`、`node_modules`、`Pods`、`.dart_tool`、`build`、`DerivedData`。
- 最终回复要短而准：说明改了哪个文件、核心内容、是否验证。除非用户要求，不要创建提交，不要推送，不要改远程仓库。

## 二、配置维护边界

- `💻JobsCodexConfigs/AGENTS.md` 是全局指导源文件；启动注入脚本后，脚本会把它部署到 `~/.codex/AGENTS.md`。
- `💻JobsCodexConfigs/skills/` 是用户级 Skills 源目录；启动注入脚本后，脚本会把其中每个技能目录部署到 `$HOME/.agents/skills/技能名/`。
- `/Users/jobs/Documents/Github/JobsConfigOS/💻JobsCodexConfigs` 是 Jobs 本地 Codex 公约文件的备份源目录，里面的 `AGENTS.md` 和 `skills/` 分别对应运行态的 `/Users/jobs/.codex/AGENTS.md` 和 `/Users/jobs/.agents/skills/`。
- 维护本仓库时坚持单向部署：只允许从 `💻JobsCodexConfigs` 写入 MacOS 当前用户的固定目标位置；不要把系统里的 `~/.codex/AGENTS.md`、`$HOME/.agents/skills` 或其它运行态文件回写到本仓库。
- 如果用户要求更新专项规则，优先更新对应 `skills/<skill-name>/SKILL.md`；只有长期全局行为才写入本 `AGENTS.md`。
- `~/.codex/AGENTS.md` 是全局指导文件位置，不是 Skills 主目录；Skills 的用户级位置是 `$HOME/.agents/skills`，仓库级位置是项目里的 `.agents/skills`。
- 仓库里的 `.agents/skills` 适合项目团队共享；本配置仓库的 `skills/` 是待部署源目录，不等同于某个业务项目的仓库级 Skills。

## 三、Skills 索引

- `jobs-macos-shell`：MacOS 原生 Shell / zsh / `.command` / Homebrew / fzf / 自检 / 批量脚本。
- `jobs-git-repository`：Git 仓库结构、JobsMacEnvVarConfigs、安装与升级入口规则。
- `jobs-markdown-docs`：Markdown、README、技术文档、流程图、表格、外链。
- `jobs-podspec`：CocoaPods、Podspec、source、资源、依赖、xcconfig。
- `jobs-objective-c-pods`：Objective-C、本地 Pods、Core/Support、头文件、JobsOCDSL、JobsModelDSL、JobsBlock、JobsMake、点语法链式调用。
- `jobs-swift`：Swift 文件基座、JobsSwiftDSL、点语法链式调用、懒加载、SnapKit、导航栏、控制器组织。
- `jobs-python`：Python 脚本、命令行、日志、异常、依赖与测试。
- `jobs-dart-flutter`：Dart / Flutter 页面、状态、路由、资源、打包与代码生成。

## 四、专项规则加载原则

- 命中某个任务类型时，优先加载对应 Skill 的完整规则；不要把所有专项规范一次性塞回本全局文件。
- 多领域任务可以组合多个 Skill，例如整理 `.command` 并写 README 时，同时参考 `jobs-macos-shell` 和 `jobs-markdown-docs`。
- Skill 内规则与本文件冲突时，本文件只管全局边界，具体工程实践以对应 Skill 为准。
- 仓库根目录存在 `.codegraph/` 时，理解或定位代码优先使用 `codegraph_explore`；如果 MCP 工具未加载，先通过 tool search 加载，仍不可用时使用 `codegraph explore "<符号名或问题>"`。仓库没有 `.codegraph/` 时直接跳过 CodeGraph，不主动初始化索引。
- 涉及 OC / Swift 的 DSL、点语法、链式语法、`byXxx` 命名、Apple API 封装或 Jobs 自建 Model 封装时，分别加载 `jobs-objective-c-pods` / `jobs-swift`；两侧公约以“同一 DSL 思想、不同语言实现”为准。
- DSL 链式方法必须返回可继续链下去的对象；除明确的终止动作外，不写只执行副作用却返回 `void` 的 DSL。返回类型要尽量保持当前主对象类型，避免链条中途降级到父类后丢失子类点语法。

## 五、固定项目路径

- Swift 侧 iOS 项目：`/Users/jobs/Documents/Github/JobsBaseConfig/JobsBaseConfig@JobsSwiftBaseConfigDemo`。
- OC 侧新项目：`/Users/jobs/Documents/Github/JobsOCBaseConfigDemo@ByPods`。
- OC 侧老项目：`/Users/jobs/Documents/Github/JobsBaseConfig/JobsBaseConfig@JobsOCBaseConfigDemo`。
- OC 新项目由 OC 老项目升级改造而来：新项目把老项目中集成于主工程的一部分能力拆解成本地 Pods 管理，拆解过程中只做极小调整，绝大多数新项目本地 Pod 都能在老项目主工程里找到对应来源或对应功能。
- 从 OC 新项目向 OC 老项目平移能力时，要符合老项目“功能集成于主工程”的特点：不要把新项目的本地 Pod 形态照搬到老项目，也不要新增 Pod 依赖；应把源码、资源、Demo 入口和工程引用平移到老项目主工程既有目录与 target 中。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
