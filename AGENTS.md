# <span id="前言">Jobs [**Codex**](https://openai.com/codex) 全局工作规约</span>

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#jobs-toc-heading-1)
- [一、总原则](#jobs-toc-heading-2)
- [二、配置维护边界](#jobs-toc-heading-3)
- [三、Skills 索引](#jobs-toc-heading-4)
  - [3.1、Jobs 自有专项规则](#jobs-toc-heading-5)
  - [3.2、外源用户级 Skills 现用清单](#external-user-skills)
  - [3.3、插件分发 Skills 现用清单](#external-plugin-skills)
- [四、专项规则加载原则](#jobs-toc-heading-8)
- [五、固定项目路径](#jobs-toc-heading-9)
- [CodeGraph](#jobs-toc-heading-10)

</details>
<!-- jobs-toc:end -->

---

## <span id="jobs-toc-heading-1" data-jobs-toc="v2"><span id="前言">🔥 前言</span></span><!-- jobs-toc:heading-end -->

> 这份文件是 Jobs 本机 Codex 的全局指导文件，部署目标为 `~/.codex/AGENTS.md`。详细的专项规范由独立 [**JobsSkills**](https://github.com/JobsKits/JobsSkills) 仓库管理，现行工作树位于 `$HOME/.agents/skills`，让 Codex 按任务场景自动加载对应技能。

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、总原则 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 默认使用中文沟通，语气直接、清楚、偏工程实用；可以保留一点 Jobs 风格，但不要为了热闹牺牲可读性。
- 默认称呼用户为“哥”。阶段反馈和最终回复都优先以“哥，”开头，例如完成事项时回复“哥，已完成。”。
- <span id="quota-reset-only-after-exhaustion">额度重置只在耗尽后使用。</span>用户已授权自动使用重置机会时，必须等本任务适用额度实际耗尽、系统明确限流或拒绝继续执行后，才按授权次数兑换；未耗尽、接近上限、99%预警或产品允许提前使用，均不得提前消耗重置，避免浪费剩余额度。承诺自动处理前先核实当前会话的兑换入口与权限；没有可用入口或工具明确受限时立即说明并交用户接手，不虚称可以后台自动执行，不绕过限制。查询额度不等于兑换；兑换后核对可验证结果，没有操作回执或可核对记录时，不得把用量归零、剩余次数变化、周期恢复或平台赠送推断成“已兑换”。不超出用户授权次数，也不擅自购买／充值。
- 每次任务开始前必须加载 `jobs-obsidian-memory`：先扫描 `/Users/jobs/Documents/Github/JobsGenesis/JobsConfigOS/📒CodexByObsidian/JobsCodexMemory` 目录，再读取 `00-记忆入口.md`、稳定偏好、工作流决策和当前项目命中的笔记；不得因为记忆库变大就全量注入无关正文。
- 任务中或结束前如果产生经用户确认的长期规划、稳定偏好、工作流决策或项目约束，必须按 `jobs-obsidian-memory` 去重后写入永久记忆库并更新索引；不写入密码、Token、私钥、Cookie、临时闲聊或未验证推断。
- 先读现有仓库和同类文件，再动手改。优先复用 `./..`、`../../JobsGenesis`、`../../JobsDocs/🔥Shell脚本代码片段.md/Shell脚本代码片段.md`、`~/Documents/JobsOCBaseConfigDemo/JobsByPods` 的现成风格。
- 默认只改用户要求范围内的文件。遇到已有改动，不回滚、不覆盖、不顺手重构。
- App 功能对齐先做资产盘点，再依据盘点表补齐；以后每次修改 App，必须在同一任务内同步对应资产盘点表的入口、行为、默认值、持久化、生命周期、代码位置、差异与验证状态，区分源码已实现、实际已验和待核项，不能把旧报表当成当前实现。盘点与项目报告集中到项目根目录的 `项目相关报告/`，根目录 `README.md` 必须保留；报告迁移时同步相对链接和工程引用，保留工具要求的固定配置入口。
- 工程内路径默认可迁移：脚本、App 启动器、源码导入、资源和配置优先使用相对路径或语言原生包引用，不硬编码开发机的用户目录、仓库位置或盘符，也不隐式依赖启动工作目录。路径基准从脚本 / App 实际位置或项目根目录解析；系统约定目录或工具路径、运行时解析得到的绝对路径和用户显式传入路径可按需使用，但不能把本机路径固化为分发产物的运行依赖。脚本与 [**Flutter**](https://flutter.dev/) import 的具体规则分别归 `jobs-macos-shell`、`jobs-dart-flutter`。
- 所有代码任务默认只修改 Jobs 本人编写或已明确由 Jobs 接管维护的源码。根目录 `Pods/`、`ManualBy*Pods@Pods`、`PodsManual`、手工第三方、供应商和生成代码，以及文件头、版权或路径显示为他人作者的源码一律排除；即使这些文件位于项目或本地 Pod 内也不得修改。所有权不明确时先排除并报告，只有用户明确点名授权后才进入。
- 用户在主任务执行过程中插入临时问题时，先回答插入问题；回答完成后必须主动回到被打断的主流程继续推进。除非用户明确说“暂停 / 停止 / 改做新任务”，否则不能把插入问题当成本轮终点。若不确定主流程停在哪一步，先用一句话复述当前主流程状态和下一步，再继续执行。
- 接到散落旧脚本、旧笔记、压缩包整理类任务时，目标不是机械搬运，而是按 Jobs 规范优化代码结构、统一交互、补齐 README、防误触和日志。
- 凡是任务需要查找、下载或补充图片、图标、占位图、圆形图标及其它 UI 视觉素材，统一先去 [**阿里巴巴矢量图标库 iconfont**](https://www.iconfont.cn/) 查找并下载或复用合适素材；iconfont 没有合适素材时，主动通过 [**Google**](https://www.google.com/) 搜索官方站点、[**Wikipedia**](https://www.wikipedia.org/) / [**Wikimedia Commons**](https://commons.wikimedia.org/) 等可追溯来源，尤其是国旗、组织标识等专有实体，无须为切换来源再次征求许可。用户已提供明确素材时优先使用指定来源。核对图片主体、来源与许可，下载到项目本地资源目录并记录出处；除非用户明确要求网络图片，运行时使用打包资源，不引用外链。不得使用来源不明图片、临时纯色块或无意义占位替代。
- 凡是编写带图形用户界面（GUI）的程序，无论使用何种语言、框架或平台，都必须提供可用的国际化多语言切换和主题切换两项基础功能。
  - 主题切换至少提供：白天 / 黑夜 / 跟随系统。
  - 国际化多语言切换至少完整支持：简体中文 / 繁体中文 / 藏文 / 英文 / 日文 / 法文 / 西班牙文 / 德文 / 俄罗斯文 / 韩文。
- 所有前端统一执行“服务端优先、本地演示回退”：页面进入 / 刷新和用户写操作都正常请求 API；首屏可先绘制本地假数据让 UI 立即出现，请求成功后用服务端响应替换，失败、超时或响应无法解析时继续用本地假数据并在本地处理可演示操作。接口恢复后，后续成功响应自动覆盖为真数据，不需要手动切换模式。用短且可配置的超时保证未部署服务器时仍能快速看到页面。
- 前端每个动态数据列表都必须提供无数据占位和重新加载入口。iOS 优先复用 Jobs `JobsEmptyAuto` 的 UIButton 空态模块；其它端使用项目既有等价控件，不用单行错误文字替代完整空态。
- 用户明确要求网络图片时，按上述素材来源顺序选取；界面先显示已随应用打包的本地 Logo，再异步加载选定来源的图片，失败后保留本地 Logo。部署说明要写明 API 回退、占位、图片兜底和离线预览方式。
- 注释要精简扼要，只解释“为什么这样做”或“这段负责什么”。不要给每行显而易见的赋值写冗长注释。
- [**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) / [**Swift**](https://www.swift.org/) 文件头注释必须使用 Jobs 标准模板，包含文件名、模块名和 `Created by Jobs on yyyy年M月d日，星期X.`，不要保留只有文件名和模块名的简化头；文件头注释区域和 `#import` / `import` 导入区域之间必须保留一个空行。
- OC / Swift 代码以人工阅读为优先，函数、分支、循环、closure / Block 与 DSL 正常提行、逐层缩进，不压成一行或用分号串联动作；`return` 独立成行。具体格式归对应 Skill 的可读性章节，替代旧的 `};return` 紧凑规则。
- 不主动执行有副作用的大命令，除非用户明确要求或当前任务必须验证。包括但不限于 `sudo`、`rm -rf`、`chmod -R`、`git reset --hard`、`git clean`、`brew upgrade`、`pod install`、`flutter clean`、`xcodebuild`。
- 网络代理属于侵入性环境变更：操作前说明目的、影响范围、风险和恢复方式，默认限定当前进程及其子进程；必须能随时切回原状态并保留脱敏审计记录，未经明确授权不得持久化或扩大到系统全局。脚本的模式选择、精确备份、恢复与验证遵循 `jobs-macos-shell`。
- 批量处理文件时默认跳过 `.git`、`node_modules`、`Pods`、`.dart_tool`、`build`、`DerivedData`。
- 最终回复要短而准：说明改了哪个文件、核心内容、是否验证。除非用户要求，不要创建提交，不要推送，不要改远程仓库。

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、配置维护边界 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- `💻JobsCodexConfigs/AGENTS.md` 是全局指导源文件。每次新增或修改全局指导后，必须在同一任务结束前同步到 `~/.codex/AGENTS.md`，并用 `cmp` 验证逐字节一致，不等待下次启动注入脚本或用户提醒；同步前先比较差异，运行态有有效独有规则时先并回标准源，保留已有改动。配置注入仍以该标准源为部署来源；本地文件同步不代表授权 Git 提交或推送。
- 双机分工：工作电脑不能运行 Codex，只在 WorkBuddy 侧创作（灵感、蒸馏出的新习惯通常先落在 WorkBuddy）；私人电脑跑 Codex。因此工作机上产生的 Skill 与全局规则一律以 WorkBuddy 为起点，由 AI 在同一任务内补齐 Codex 对应规则，不要求用户再手工维护第二份。
- 转译口径：WorkBuddy 用户级 Skill 增删改后，Codex 本机的对应专项规则写入 `$HOME/.agents/skills/<skill-name>/SKILL.md` 运行态，不直接改备份子模块——宿主措辞改回 Codex、运行态路径改回 `/Users/jobs/...`、Skill 目录改回 `$HOME/.agents/skills`、记忆目录改回 `~/.codex/memories`；长期全局行为同时写进本 `AGENTS.md`。必须做语义改写，禁止把 `~/.workbuddy/skills` 整目录原样拷进 Codex 配置目录。
- 单向收口：本仓库只存 Codex 侧的 `AGENTS.md` 与 `skills/`，不存任何 WorkBuddy 镜像或渲染产物。WorkBuddy 侧只在那台工作机上维护（`~/.workbuddy/skills` 与个人 `MEMORY.md`），同步方向永远是 WorkBuddy → 本仓库的语义转译，不存在从本仓库反向生成 WorkBuddy 文件的路径。
- [**JobsSkills**](https://github.com/JobsKits/JobsSkills) 是用户级 Skills 的独立标准仓库；运行态 `/Users/jobs/.agents/skills` 是现行、内容最完整的基准工作树，备份态为 `/Users/jobs/Documents/Github/JobsGenesis/JobsConfigOS/💻JobsCodexConfigs/skills`，不得自动用备份态反向覆盖运行态。
- 运行态 Skills 的日常新增、修改或删除只维护现行工作树，不直接编辑备份态，也不将运行态文件复制到备份态，不以两态一致作为任务完成条件。备份态只在首次使用时用于环境部署，后续配置更新通过 Git 拉取；不因日常修改或审计差异自动部署、拉取或补齐备份，具体核验遵循 `jobs-codex-config-audit`。部署或拉取不授权提交、推送或更新父仓 gitlink。
- `💻JobsCodexConfigs/skills` 只作为 `JobsSkills` 的 Git 子模块挂载；父仓只跟踪 `.gitmodules` 和 gitlink 指针，不再跟踪该目录内的独立文件。
- 修改专项规则时，以 `$HOME/.agents/skills/<skill-name>/SKILL.md` 所在的 `JobsSkills` 工作树为基准，不直接改备份态；只有用户明确授权版本发布时，才单独提交、推送 `JobsSkills`，再在 `💻JobsCodexConfigs` 中更新子模块指针。
- Codex 配置注入脚本只从 `💻JobsCodexConfigs/AGENTS.md` 部署全局指导，并扫描现行 `JobsSkills` 工作树生成受控注册块；不复制、删除或覆盖 `JobsSkills` 内容。
- Obsidian 永久记忆库是跨项目用户数据，不属于 `💻JobsCodexConfigs` 的部署副本；只能按记忆协议直接读写 Vault，不得将整个 Vault 拷贝进 Skills 或运行态配置目录。
- 如果用户要求更新专项规则，优先更新 `JobsSkills` 仓库中对应 `<skill-name>/SKILL.md`；只有长期全局行为才写入本 `AGENTS.md`。
- `~/.codex/AGENTS.md` 是全局指导文件位置，不是 Skills 主目录；Skills 的用户级位置是 `$HOME/.agents/skills`，仓库级位置是项目里的 `.agents/skills`。
- 仓库里的 `.agents/skills` 适合项目团队共享；`JobsSkills` 是用户级独立仓库，不等同于某个业务项目的仓库级 Skills。
- 所有外源性 Skills（第三方实体、外援软链接及插件分发）都必须登记在本公约的现用清单，便于换机恢复。以后安装、更新、替换、停用、卸载或明确弃用时，在同一任务内按最新实际状态更新名称、用途、来源、版本依据和恢复方式；弃用、卸载及被替代项移出现用清单，保留安装但停用的须标明状态。清单只反映当前保留项，不累积历史安装记录，不把缓存残留或本轮暂未注入当成安装或弃用证据。更新后按本节同步运行态并验证，不因此安装、卸载、提交或推送。

## <span id="jobs-toc-heading-4" data-jobs-toc="v2">三、Skills 索引 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

### <span id="jobs-toc-heading-5" data-jobs-toc="v2">3.1、Jobs 自有专项规则 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- `jobs-macos-shell`：MacOS 原生 Shell / zsh / `.command` / Homebrew / fzf / 自检 / 批量脚本。
- `jobs-git-repository`：Git 仓库结构、JobsMacEnvVarConfigs、安装与升级入口规则。
- `jobs-github-actions`：跨项目 [**GitHub Actions**](https://docs.github.com/en/actions) workflow、复用与复合 action、CI 失败排查、推送前检查和远端验收。
- `jobs-markdown-docs`：Markdown、README、技术文档、流程图、表格、外链。
- `jobs-frontend-experience`：模糊需求、竞品案例或只提取几个功能涉及 Web／H5、移动 App、小程序页面时必须加载，按本期业务任务补齐页面、视觉与交互闭环。
- `jobs-codex-config-audit`：AGENTS、Skills、规则去重、语义防回退、中文序号、固定链接与单向部署巡检。
- `jobs-obsidian-memory`：Obsidian 跨项目永久记忆、任务前读取、长期信息沉淀、去重、冲突与每日复盘。
- `jobs-podspec`：CocoaPods、Podspec、source、资源、依赖、xcconfig。
- `jobs-objective-c-pods`：Objective-C、本地 Pods、Core/Support、头文件、JobsOCDSL、JobsModelDSL、JobsBlock、JobsMake、点语法链式调用。
- `jobs-swift`：Swift 文件基座、JobsSwiftDSL、点语法链式调用、懒加载、SnapKit、导航栏、控制器组织。
- `jobs-python`：Python 脚本、命令行、日志、异常、依赖与测试。
- `jobs-dart-flutter`：Dart / Flutter 页面、状态、路由、资源、打包与代码生成。
- `jobs-auth-switch-motion`：JobsAppDoor 登录/注册切换动效、面板变形、卡片横滑、入口弹出与键盘顶起。
- `jobs-lottie-stroke-writing`：汉字笔顺 Lottie、一笔一画手写、hanzi-writer-data、trim path、未写不显。
- `hacker`：Hacker、安全研究、恶意仓库静态审阅、授权渗透测试边界、蓝队排查、IOC 和 HTTP 代理安全测试。

### 3.2、<span id="external-user-skills">外源用户级 Skills 现用清单</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

核对日期：2026-11-14。以下 24 个入口均在 `$HOME/.agents/skills`；其中包含嵌套入口。表内“随仓恢复”指已被 JobsSkills 跟踪，“独立重装／重建”指被忽略，单独克隆 JobsSkills 不会恢复。上游内容继续保留第三方所有权；本地格式适配不等于接管上游。

| 当前入口 | 用途 | 来源与恢复基线 |
| --- | --- | --- |
| `frontend-design` | 前端视觉、排版与构图 | [**Anthropic Skills**](https://github.com/anthropics/skills)，`skills/frontend-design`；提交 `2c5958ecac7cee2b583967a2c4981d0f4a75c579`，独立重装 |
| `ui-ux-pro-max` | 跨端 UI／UX 与设计系统 | [**UI UX Pro Max**](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)，`.claude/skills/ui-ux-pro-max`；提交 `6ae86f61f520d6ca229d2f40e070410638c908c5`，独立重装；入口使用同提交官方 Codex 全局模板 |
| `impeccable` | 界面设计、点评与精修 | [**Impeccable**](https://github.com/pbakaus/impeccable)，`.agents/skills/impeccable`；提交 `c1e0e5492fbb524f5df84d635ecfae7dc438ec45`，独立重装 |
| `web-design-guidelines` | Web 界面规范审查 | [**Vercel Agent Skills**](https://github.com/vercel-labs/agent-skills)，`skills/web-design-guidelines`；提交 `1a2c79d4e6c4a2283dc2c614b6538cbe1ed5ca62`，独立重装 |
| `graphify` | 文件与代码知识图谱 | [**Graphify**](https://github.com/safishamsi/graphify)，Skill 随仓恢复；另装工具包 `graphifyy==0.8.20`，命令 `graphify` |
| `motion-design` | 动效、缓动与动画编排 | [**LottieFiles Motion Design Skill**](https://github.com/LottieFiles/motion-design-skill)，`skills/motion-design`，版本 `1.0.0`；随仓恢复 |
| `microsoft-foundry` | 模型、资源与 Agent 生命周期 | [**Microsoft Azure Skills**](https://github.com/microsoft/azure-skills)，`.github/plugins/azure-skills/skills/microsoft-foundry`，根版本 `1.2.32`；完整包随仓恢复 |
| `finetuning` | 模型微调、训练与评估 | 同 Foundry 包，位于 `microsoft-foundry/finetuning`；随仓恢复 |
| `deploy-model` | 模型部署路由 | 同包，位于 `microsoft-foundry/models/deploy-model`；随仓恢复 |
| `capacity` | 区域容量与配额查询 | 同包，位于 `microsoft-foundry/models/deploy-model/capacity`；随仓恢复 |
| `customize` | 自定义模型部署 | 同包，位于 `microsoft-foundry/models/deploy-model/customize`；随仓恢复 |
| `preset` | 快速选择区域并部署 | 同包，位于 `microsoft-foundry/models/deploy-model/preset`；随仓恢复 |
| `personal-avatar-memory` | 数字分身长期记忆 | 原始上游 URL 待核；现有完整目录随仓恢复 |
| `personal-avatar-soul` | 数字分身人格 | 原始上游 URL 待核；现有完整目录随仓恢复 |
| `personal-avatar-summary` | 数字分身摘要 | 原始上游 URL 待核；现有完整目录随仓恢复 |
| `personal-avatar-user` | 数字分身用户画像 | 原始上游 URL 待核；现有完整目录随仓恢复 |
| `understand` | 生成代码知识图谱 | [**Understand Anything**](https://github.com/Lum1104/Understand-Anything)，独立仓及软链接按下文重建 |
| `understand-chat` | 基于图谱问答 | 同 Understand Anything |
| `understand-dashboard` | 图谱可视化面板 | 同 Understand Anything |
| `understand-diff` | 代码差异与影响分析 | 同 Understand Anything |
| `understand-domain` | 业务领域图谱 | 同 Understand Anything |
| `understand-explain` | 模块与函数解释 | 同 Understand Anything |
| `understand-knowledge` | Wiki 知识图谱 | 同 Understand Anything |
| `understand-onboard` | 新人上手指引 | 同 Understand Anything |

- 四项前端实体的内容哈希、源路径、模板及引擎恢复依据在 `$HOME/.agents/skills/frontend-skills.lock.json`；Impeccable 当前配套引擎 `0.1.22`，换机按目标平台匹配，不照搬本机二进制。
- Foundry 的 `$HOME/.agents/.skill-lock.json` 记录来源及目录哈希 `15b425217b643229a34baf34eb1def65bb637308`；它不是 Git 提交号。`finetuning` 的占位版本也不能用作版本锁。
- Understand Anything 独立仓为 `$HOME/.understand-anything/repo`，基线提交 `5c1e35f90be029efb012a41e1122b08abef5cbb2`；先恢复该仓，再把八个同名入口链接到其 `understand-anything-plugin/skills/<入口名>`。完整映射见 JobsSkills 根 `README.md`，不要只复制旧机器的绝对路径软链接。
- 四项 Avatar 的 `.personal-avatar-skills.version` 只有名称清单，没有来源 URL 或版本锁；换机使用 JobsSkills 中现有已跟踪目录，不猜测下载地址。

### 3.3、<span id="external-plugin-skills">插件分发 Skills 现用清单</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

核对日期：2026-11-14。按已安装／启用资料及实际可用的插件核对；包内辅助入口不一定在每轮全部公开。此处登记用于恢复，不要求加载全部 Skill。[**OpenAI 插件 Skills**](https://developers.openai.com/plugins/concepts/skills)由对应插件分发，版本列为本次核对值。

| 插件名与来源市场 | 当前版本 | 用途与包内 Skill 入口 |
| --- | --- | --- |
| `data-analytics@openai-curated-remote` | `1.2.0` | 数据分析与报告：`analyze-data-quality`、`answers-follow-up`、`build-dashboard`、`build-report`、`convert-to-doc`、`convert-to-slides`、`customize-data-plugin`、`design-kpis`、`index`、`jupyter-notebooks`、`kpi-reporting`、`market-sizing`、`metric-diagnostics`、`onboarding`、`product-business-analysis`、`publish-artifact-to-sites`、`report-to-pdf`、`schedule-refresh-jobs`、`share-artifact-summary`、`validate-data`、`visualize-data` |
| `figma@openai-curated-remote` | `18.0.0` | 设计与代码互通：`figma-code-connect`、`figma-code-workflows`、`figma-create-new-file`、`figma-design-to-code`、`figma-generate-design`、`figma-generate-diagram`、`figma-generate-library`、`figma-generative-plugins`、`figma-implement-motion`、`figma-shaders`、`figma-spec`、`figma-swiftui`、`figma-use`、`figma-use-figjam`、`figma-use-motion`、`figma-use-slides` |
| `google-drive@openai-curated-remote` | `0.1.23` | 云盘与办公文档：`google-docs`、`google-drive`、`google-drive-comments`、`google-sheets`、`google-slides` |
| `product-design@openai-curated-remote` | `0.1.56` | 产品设计与原型：`audit`、`design-qa`、`get-context`、`ideate`、`image-to-code`、`index`、`research`、`share`、`url-to-code`、`user-context` |
| `sites@openai-curated-remote` | `1.1.6` | 网站创建与发布：`sites`、`sites-remix` |
| `pages@openai-curated-remote` | `0.1.26` | 页面与空间：`maintain-space`、`manage-schedules`、`organize-space`、`write-page` |
| `plugin-management@openai-curated-remote` | `0.1.0` | 插件发现与管理：`plugin-management` |
| `visualize@openai-curated-remote` | `1.0.103` | 交互可视化：`visualize` |
| `work-pets@openai-curated-remote` | `0.1.6` | 数字宠物：`create-pet`、`pets`、`update-pet` |
| `documents@openai-primary-runtime` | `26.1111.10934` | 文档制作与修改：`documents` |
| `pdf@openai-primary-runtime` | `26.1111.10934` | PDF 读写与核验：`pdf` |
| `presentations@openai-primary-runtime` | `26.1111.10934` | 演示文稿：`Presentations` |
| `spreadsheets@openai-primary-runtime` | `26.1111.10934` | 表格文件与在线会话：`Spreadsheets`、`excel-live-control` |
| `template-creator@openai-primary-runtime` | `26.1111.10934` | 可复用模板 Skill：`template-creator` |
| `visualize@openai-bundled` | `1.0.91` | 应用自带且配置启用的可视化包；与上面的市场包来源不同，按实际注入使用 |

- 换机按“插件名＋来源市场”在当前 Codex 插件目录恢复；需要连接服务的插件重新完成本人账户授权。`openai-primary-runtime` 和 `openai-bundled` 随应用环境提供，核对启用状态，不把缓存或本机临时目录当成可移植安装包。
- 本地核对依据为 `$HOME/.codex/config.toml` 中的插件配置、插件安装状态及 `plugins/cache/<来源市场>/<插件>/<版本>/.codex-plugin/plugin.json`；缓存存在本身不证明仍安装或启用。内置 `.system` Skills 和仅提供工具、没有 Skill 的包不混入外源手动安装清单。

## <span id="jobs-toc-heading-8" data-jobs-toc="v2">四、专项规则加载原则 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 命中某个任务类型时，优先加载对应 Skill 的完整规则；不要把所有专项规范一次性塞回本全局文件。
- 编写、修改或审查 `.github/workflows/`、复用 workflow、复合 action，排查 [**GitHub Actions**](https://docs.github.com/en/actions) 失败，或推送需验收 Actions 检查的变更时，必须加载 `jobs-github-actions`；跨项目适用，不能以本地通过或推送成功代替同一提交的远端验收。每次遇到 workflow 失败，必须在同一任务内复盘、蒸馏并回写该 Skill，无须用户再次提醒，具体去重与证据边界按其失败复盘条款执行。
- 写或改 `SKILL.md` 时，优先在现有对应 Skill 上收口；只有长期独立领域、触发边界清晰、现有 Skill 无法承载时，才新增 Skill，不要动不动就新建。
- 新增规则前先查同文件和相关 Skill 是否已有同义规则，优先合并或改写原规则；保留非显而易见的工程判断、目录边界、验证步骤和风险提示，删除口号式、重复解释或临时记录。
- 多领域任务可以组合多个 Skill，例如整理 `.command` 并写 README 时，同时参考 `jobs-macos-shell` 和 `jobs-markdown-docs`。
- Skill 内规则与本文件冲突时，本文件只管全局边界，具体工程实践以对应 Skill 为准。
- 仓库根目录存在 `.codegraph/` 时，理解或定位代码优先使用 `codegraph_explore`；如果 MCP 工具未加载，先通过 tool search 加载，仍不可用时使用 `codegraph explore "<符号名或问题>"`。仓库没有 `.codegraph/` 时直接跳过 CodeGraph，不主动初始化索引。
- 涉及 OC / Swift 的 DSL、点语法、链式语法、`byXxx` 命名、Apple API 封装或 Jobs 自建 Model 封装时，分别加载 `jobs-objective-c-pods` / `jobs-swift`；两侧公约以“同一 DSL 思想、不同语言实现”为准。
- DSL 链式方法必须返回可继续链下去的对象；除明确的终止动作外，不写只执行副作用却返回 `void` 的 DSL。返回类型要尽量保持当前主对象类型，避免链条中途降级到父类后丢失子类点语法。

## <span id="jobs-toc-heading-9" data-jobs-toc="v2">五、固定项目路径 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- Obsidian 永久记忆仓库：`/Users/jobs/Documents/Github/JobsGenesis/JobsConfigOS/📒CodexByObsidian`；实际 Vault：`📒CodexByObsidian/JobsCodexMemory`。
- Swift 侧 iOS 项目：`../../JobsBaseConfig/JobsBaseConfig@JobsSwiftBaseConfigDemo`。
- SwiftUI 侧 iOS 项目：`../../JobsBaseConfig/JobsBaseConfig@JobsSwiftUIBaseConfigDemo`（本机：`/Users/jobs/Documents/Github/JobsBaseConfig/JobsBaseConfig@JobsSwiftUIBaseConfigDemo`）。
- OC 侧新项目：`../../JobsOCBaseConfigDemo@ByPods`。
- OC 侧老项目：`../../JobsBaseConfig/JobsBaseConfig@JobsOCBaseConfigDemo`。
- 李林哲项目：`/Users/jobs/Documents/Github/啄木鸟维修平台-V3.8`。
- 陈泉羽项目：`/Users/jobs/Documents/Github/学术服务平台`。
- OC 新项目由 OC 老项目升级改造而来：新项目把老项目中集成于主工程的一部分能力拆解成本地 Pods 管理，拆解过程中只做极小调整，绝大多数新项目本地 Pod 都能在老项目主工程里找到对应来源或对应功能。
- 从 OC 新项目向 OC 老项目平移能力时，要符合老项目“功能集成于主工程”的特点：不要把新项目的本地 Pod 形态照搬到老项目，也不要新增 Pod 依赖；应把源码、资源、Demo 入口和工程引用平移到老项目主工程既有目录与 target 中。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>

<!-- CODEGRAPH_START -->
## <span id="jobs-toc-heading-10" data-jobs-toc="v2">CodeGraph <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
<!-- CODEGRAPH_END -->
