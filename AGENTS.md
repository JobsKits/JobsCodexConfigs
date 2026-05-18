# Jobs [**Codex**](https://openai.com/codex) 工作规约

![Jobs倾情奉献](https://picsum.photos/1500/400 "Jobs出品，必属精品")

[toc]

---

## 🔥 <font id=前言>前言</font> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

> 这份文件是 Jobs 本机 [**Codex**](https://openai.com/codex) 的长期工作约定。默认优先服务 MacOS 原生 Shell / `.sh` / `.command` 脚本、[**Markdown**](https://markdown.cn) 文档、[**CocoaPods**](https://cocoapods.org/) `*.podspec`，并预留 OC、[**Swift**](https://www.swift.org/)、[**Python**](https://www.python.org)、[**Dart**](https://dart.dev) / [**Flutter**](https://flutter.dev/) 的写作规范。

## 一、总原则 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 默认使用中文沟通，语气直接、清楚、偏工程实用；可以保留一点 Jobs 风格，但不要为了热闹牺牲可读性。
- 先读现有仓库和同类文件，再动手改。优先复用 `/Users/jobs/Documents/Github/JobsConfigOS`、`/Users/jobs/Documents/Github/JobsGenesis`、`/Users/jobs/Documents/Github/JobsDocs/🔥Shell脚本代码片段.md/Shell脚本代码片段.md`、`/Users/jobs/Documents/JobsOCBaseConfigDemo/JobsByPods` 的现成风格。
- 默认只改用户要求范围内的文件。遇到已有改动，不回滚、不覆盖、不顺手重构。
- 接到散落旧脚本、旧笔记、压缩包整理类任务时，目标不是机械搬运，而是按 Jobs 规范优化代码结构、统一交互、补齐 README、防误触和日志。
- 注释要精简扼要，只解释“为什么这样做”或“这段负责什么”。不要给每行显而易见的赋值写冗长注释。
- 不主动执行有副作用的大命令，除非用户明确要求或当前任务必须验证。包括但不限于 `sudo`、`rm -rf`、`chmod -R`、`git reset --hard`、`git clean`、`brew upgrade`、`pod install`、`flutter clean`、`xcodebuild`。
- 批量处理文件时默认跳过 `.git`、`node_modules`、`Pods`、`.dart_tool`、`build`、`DerivedData`。
- 最终回复要短而准：说明改了哪个文件、核心内容、是否验证。除非用户要求，不要创建提交，不要推送，不要改远程仓库。

## 二、MacOS Shell 脚本（`.sh` / `.command`） <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 2.1、脚本基座

- 新写或升级脚本时，默认使用：

  ```shell
  #!/bin/zsh
  ```

- 默认添加：

  ```shell
  setopt NO_NOMATCH
  ```

- 脚本路径和日志路径按 Jobs 标准写法：

  ```shell
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
  SCRIPT_PATH="${SCRIPT_DIR}/$(basename -- "$0")"
  SCRIPT_BASENAME=$(basename "$0" | sed 's/\.[^.]*$//')
  LOG_FILE="/tmp/${SCRIPT_BASENAME}.log"
  : > "$LOG_FILE"
  ```

- 脚本必须结构化、模块化：基础路径、彩色日志、通用交互、路径处理、环境检查、业务逻辑分块写函数，最后只在 `main` 里编排调用。

  ```shell
  main() {
    # 主流程统一收口。
  }

  main "$@"
  ```

- 优先写原生 Shell，能用 MacOS 自带工具解决就不引入 [**Python**](https://www.python.org) / [**Node.js**](https://nodejs.org/) / [**Ruby**](https://www.ruby-lang.org/) 依赖。
- 采用 Shell 脚本的原因：Shell 来自 MacOS 原生系统底层，虽然写法相对繁琐冗杂，但执行效率高，并且不需要额外介入 [**Ruby**](https://www.ruby-lang.org)、[**Python**](https://www.python.org) 等第三方运行环境，因此具备更好的移植性。
- 涉及批量文件处理时，使用 `find ... -print0` + `while IFS= read -r -d ''`，路径必须全程加引号，兼容空格、中文、括号和特殊符号。
- 涉及文本替换时，优先使用 `grep -Fq`；复杂替换可以使用 `perl`，避免脆弱的 `sed` 转义。

### 2.2、彩色日志

- 新脚本默认带这一组函数；已有脚本按原风格补齐即可。

  ```shell
  log()            { echo -e "$1" | tee -a "$LOG_FILE"; }
  color_echo()     { log "\033[1;32m$1\033[0m"; }         # 正常绿色输出
  info_echo()      { log "\033[1;34mℹ $1\033[0m"; }       # 信息
  success_echo()   { log "\033[1;32m✔ $1\033[0m"; }       # 成功
  warn_echo()      { log "\033[1;33m⚠ $1\033[0m"; }       # 警告
  warm_echo()      { log "\033[1;33m$1\033[0m"; }         # 温馨提示
  note_echo()      { log "\033[1;35m➤ $1\033[0m"; }       # 说明
  error_echo()     { log "\033[1;31m✖ $1\033[0m"; }       # 错误
  err_echo()       { log "\033[1;31m$1\033[0m"; }         # 错误纯文本
  debug_echo()     { log "\033[1;35m🐞 $1\033[0m"; }      # 调试
  highlight_echo() { log "\033[1;36m🔹 $1\033[0m"; }      # 高亮
  gray_echo()      { log "\033[0;90m$1\033[0m"; }         # 次要信息
  bold_echo()      { log "\033[1m$1\033[0m"; }            # 加粗
  underline_echo() { log "\033[4m$1\033[0m"; }            # 下划线
  ```

- 终端输出和日志落盘必须同步，排查时能直接看 `/tmp/脚本名.log`。
- 成功、警告、错误要有明确前缀。失败分支不要静默吞掉，至少输出失败命令或目标路径。

### 2.3、交互约定

- `.command` 双击脚本优先显示同目录 `README.md`，用户按回车后继续，`Ctrl+C` 取消。

  ```shell
  show_readme_and_wait() {
    local readme_path="${SCRIPT_DIR}/README.md"
    clear
    if [[ -f "$readme_path" ]]; then
      highlight_echo "============================== README.md =============================="
      cat "$readme_path" | tee -a "$LOG_FILE"
      highlight_echo "======================================================================="
    else
      warn_echo "未找到 README.md，继续执行内置流程说明。"
    fi
    echo ""
    read -r "?👉 已阅读自述文件，按回车继续执行；按 Ctrl+C 取消：" _
  }
  ```

- 普通安装 / 更新 / 升级 / 自检类操作统一为：直接回车跳过，输入任意字符后回车执行。
- 只要涉及“升级 / 更新 / upgrade / update”，都必须遵守这条规则；不要写成“回车执行升级，输入任意字符跳过”。

  ```shell
  ask_any_to_run() {
    local message="$1"
    local answer=""
    read -r "?${message}（直接回车跳过；输入任意字符后回车执行）：" answer
    [[ -n "$answer" ]]
  }
  ```

- 危险操作必须要求输入 `YES`，不能把回车设计成执行。

  ```shell
  confirm_yes() {
    echo ""
    warn_echo "⚠ $1"
    gray_echo "危险操作必须输入 YES 后回车；其它输入一律取消。"
    local input=""
    IFS= read -r "input?➤ "
    [[ "$input" == "YES" ]]
  }
  ```

- 用户拖入路径时，必须去除首尾引号、回车，并兼容多个路径。

  ```shell
  strip_outer_quotes() {
    local value="$1"
    value="${value%$'\r'}"
    value="${value%$'\n'}"
    value="${value#\"}"
    value="${value%\"}"
    value="${value#\'}"
    value="${value%\'}"
    print -r -- "$value"
  }
  ```

### 2.4、[**Homebrew**](https://brew.sh/) / MacOS 环境

- [**Homebrew**](https://brew.sh/) 相关脚本必须识别 Apple Silicon 和 Intel：

  ```shell
  get_cpu_arch() {
    [[ "$(uname -m)" == "arm64" ]] && echo "arm64" || echo "x86_64"
  }
  ```

- 查找 `brew` 时按顺序兼容：`command -v brew`、`/opt/homebrew/bin/brew`、`/usr/local/bin/brew`。
- 写入 shellenv 时必须防重复追加，使用明显的 header / footer 块。
- 写入配置后要让当前终端立即生效：`eval "$shellenv_cmd"`。
- 已安装 [**Homebrew**](https://brew.sh/) 时，不自动执行 `brew update && brew upgrade && brew cleanup && brew doctor && brew -v`，必须询问用户。
- 涉及 CLT、[**Xcode**](https://developer.apple.com/xcode/)、[**CocoaPods**](https://cocoapods.org/)、[**Flutter**](https://flutter.dev/)、[**Android Studio**](https://developer.android.com/studio?hl=zh-c)、[**Java**](https://www.java.com/)、[**Ruby**](https://www.ruby-lang.org/)、[**Node.js**](https://nodejs.org/) 等工具链时，先检查再执行，失败时输出下一步排查方向。

### 2.5、批量脚本 / 压缩包输出

- 当用户要求整理脚本并输出压缩文件时，最终结构必须是“每个脚本一个文件夹”。
- 文件夹名使用脚本完整文件名，包含后缀，例如：

  ```text
  【MacOS】⚙️运行授权.command/
  ├── 【MacOS】⚙️运行授权.command
  └── README.md
  ```

- 文件夹内除了脚本本体，必须生成同风格 `README.md`。
- 如果原始输入是散落脚本，整理时优先保留原脚本名；只在明显错误、重复或不符合 Jobs 命名时，才做最小必要改名。
- 批量升级脚本时，默认做结构优化：统一 `#!/bin/zsh`、路径变量、彩色日志、README 阻塞、防误触、`main "$@"`、[**Homebrew**](https://brew.sh/) 自检和升级交互。
- 输出压缩包前应做静态检查和结构检查；无法执行 MacOS 专属命令时，README 或最终说明里写清楚“未实际执行”。

### 2.6、Shell 验证

- Shell 脚本优先做静态检查：

  ```shell
  zsh -n '脚本名.command'
  ```

- 修改 `.command` 后确认 shebang、`SCRIPT_DIR` / `LOG_FILE`、`main "$@"`、路径引号、危险操作 `YES` 确认、普通升级动作不是默认执行。


## 三、Git 仓库规则 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 3.1、🌍JobsMacEnvVarConfigs 仓库

- 处理 `🌍JobsMacEnvVarConfigs` 仓库时，先分清根目录入口脚本和 `scripts/` 下的解耦脚本，不要把二者混成一类。
- `scripts/` 是存放解耦脚本代码的目录；这里面的脚本主文件名对应终端里的命令名，脚本文件统一以 `.command` 作为后缀。
- `scripts/` 下每一个具体的 `*.command` 脚本，都必须由同名文件夹包裹，并且每个脚本文件夹内都必须放置这个脚本对应的 `README.md`。

  ```text
  scripts/
  ├── install.command/
  │   ├── install.command
  │   └── README.md
  └── update.command/
      ├── update.command
      └── README.md
  ```

- `scripts/install.command` 和与 `scripts/` 平级的 `install.command` 不是同一个职责：

  | 入口位置 | 核心职责 | 处理原则 |
  | -------- | -------- | -------- |
  | `scripts/install.command` | 利用 `zsh` 配置安装 MacOS 系统的各种自定义依赖。 | 面向依赖安装和本机环境构建。 |
  | `install.command` | 将 `JobsMacEnvVarConfigs` 内容同步到系统。 | 主要瞄准终端 `zsh` 配置同步。 |

- `scripts/update.command` 是全员升级入口；凡是 `scripts/install.command` 新增、删除或调整安装能力，都必须同步更新 `scripts/update.command`，保持安装与升级能力平行，不允许只改安装不改升级。
- 写或改这个仓库的脚本时，要随时对照 `install.command` 和 `update.command`：安装负责“从无到有”，升级负责“已有环境持续更新”，两者覆盖的工具链和交互顺序应尽量一致。

## 四、[**Markdown**](https://markdown.cn) 文档（`*.md`） <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 4.1、整体风格

- Jobs 的 `.md` 文档默认使用中文技术笔记风格，结构清楚、标题醒目、能直接复制命令执行。
- 修改 `AGENTS.md` 本身时，也必须反哺本文件：把它当成普通 [**Markdown**](https://markdown.cn) 技术文档同步套用本章规则，专有名词按固定链接表补链，归属于上一条的补充内容必须右缩进。
- 文档开头可以使用 Jobs 风格封面：

  ```markdown
  # `标题`

  ![Jobs倾情奉献](https://picsum.photos/1500/400 "Jobs出品，必属精品")

  [toc]

  ---
  ```

- `前言` 是二级标题，但不参与中文序号：

  ```markdown
  ## 🔥 <font id=前言>前言</font>
  ```

- 正文二级标题优先使用中文编号：`## 一、...`、`## 二、...`。
- 三级标题使用阿拉伯编号：`### 2.1、...`、`### 2.2、...`。
- 长文档可以保留锚点和上下跳转链接：

  ```markdown
  ## 一、升级标准 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

  <a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
  ```

### 4.2、代码块与缩进

- 命令示例统一使用 fenced code block，并标注语言。
- 凡是内容属于上一条说明的补充、示例或展开，都必须向右缩进两个空格，让视觉层级归属于上一条；包括代码块、表格、引用、图片、[**Mermaid**](https://mermaid.js.org) 流程图、子列表。
- bullet 下方的代码块必须缩进两个空格，让代码块视觉上归属于这条说明；不要让代码块顶到页面左边。

  ````markdown
  - 只要涉及“升级 / 更新 / upgrade / update”，都必须遵守这条规则。

    ```shell
    ask_any_to_run() {
      local message="$1"
      local answer=""
      read -r "?${message}（直接回车跳过；输入任意字符后回车执行）：" answer
      [[ -n "$answer" ]]
    }
    ```
  ````

- bullet 下方的表格必须写成上一条的子内容：上一条 bullet 结束后保留空行，表格每一行源码都以两个空格开头，格式必须像下面这样，不要顶格写表格。

  ````markdown
  - 如果用户明确给了新的官方链接，以用户最新指定为准，顺手更新这张表。

    | 推荐写法                            | 识别别名          | 固定链接                  |
    | ----------------------------------- | ----------------- | ------------------------- |
    | [**Markdown**](https://markdown.cn) | `Markdown` / `md` | `https://markdown.cn`     |
    | [**Mermaid**](https://mermaid.js.org) | `Mermaid`         | `https://mermaid.js.org`  |
  ````

- [**Markdown**](https://markdown.cn) 中的路径、命令、文件名、变量名都用反引号包起来，例如 `LOG_FILE`、`/tmp/脚本名.log`、`README.md`。

### 4.3、外链、表格与流程图

- 能外链的第三方工具、框架、语言、平台，优先用官方链接，并按 Jobs 文档习惯写成 `[**名称**](URL)`，例如 [**Homebrew**](https://brew.sh/)、[**Flutter**](https://flutter.dev/)、[**CocoaPods**](https://cocoapods.org/)、[**Mermaid**](https://mermaid.js.org)。
- 标题、表格、正文第一次出现第三方名词时可以直接加链接；代码块、命令、路径、文件名里的字面量不要加链接。
- 表格用于阶段说明、参数说明、目录统计、命令清单；表头短一点，内容能扫读。
- 复杂流程优先使用 [**Mermaid**](https://mermaid.js.org)。
- 对用户有风险的地方要写明白，不要藏在代码块后面。危险动作必须在文档里说明确认方式，例如“必须输入 `YES` 才会继续”。
- 文档语气可以保留 Jobs 风格短句，例如“Jobs出品，必属精品”“我是有底线的”，但正文要优先服务操作，不堆装饰。

### 4.3.1、专有名词固定超链接

- 写 [**Markdown**](https://markdown.cn) / README / AGENTS 这类技术文档时，遇到下表里的专有名词，正文第一次出现时优先写成 `[**名称**](URL)`；需要强调或便于点击时，后续也可以继续加链接。
- 同一个工具有多个常见写法时，正文优先使用“推荐写法”；括号里的别名只用于识别，不强行改代码块里的命令。
- 代码块、命令、路径、文件名、变量名里的字面量不要加超链接，例如 `brew install fzf`、`Podfile`、`python3`、`go-task/tap/go-task`。
- 如果用户明确给了新的官方链接，以用户最新指定为准，顺手更新这张表。

  | 推荐写法                                                               | 识别别名                                              | 固定链接                                           |
  | ------------------------------------------------------------------ | ------------------------------------------------- | ---------------------------------------------- |
  | [**Markdown**](https://markdown.cn)                                | `Markdown` / `md`                                 | `https://markdown.cn`                          |
  | [**Swift**](https://www.swift.org/)                                | `Swift`                                           | `https://www.swift.org/`                       |
  | [**Dart**](https://dart.dev)                                       | `Dart`                                            | `https://dart.dev`                             |
  | [**Flutter**](https://flutter.dev/)                                | `Flutter`                                         | `https://flutter.dev/`                         |
  | [**Ruby**](https://www.ruby-lang.org)                              | `Ruby`                                            | `https://www.ruby-lang.org`                    |
  | [**Homebrew**](https://brew.sh/)                                   | `Homebrew` / `brew`                               | `https://brew.sh/`                             |
  | [**Gem**](https://rubygems.org/)                                   | `Gem` / `gem` / `RubyGems`                        | `https://rubygems.org/`                        |
  | [**CocoaPods**](https://cocoapods.org/)                            | `CocoaPods` / `Cocoapods` / `pod`                 | `https://cocoapods.org/`                       |
  | [**git-lfs**](https://git-lfs.com/)                                | `git-lfs` / `Git LFS`                             | `https://git-lfs.com/`                         |
  | [**gh**](https://formulae.brew.sh/formula/gh)                      | `gh` / `GitHub CLI`                               | `https://formulae.brew.sh/formula/gh`          |
  | [**nushell**](https://www.nushell.sh/)                             | `nushell` / `nu`                                  | `https://www.nushell.sh/`                      |
  | [**rbenv**](https://formulae.brew.sh/formula/rbenv)                | `rbenv`                                           | `https://formulae.brew.sh/formula/rbenv`       |
  | [**Node.js**](https://nodejs.org)                                  | `node` / `Node.js`                                | `https://nodejs.org`                           |
  | [**jenv**](https://www.jenv.be)                                    | `jenv`                                            | `https://www.jenv.be`                          |
  | [**fvm**](https://fvm.app)                                         | `fvm`                                             | `https://fvm.app`                              |
  | [**pnpm**](https://pnpm.io/)                                       | `pnpm`                                            | `https://pnpm.io/`                             |
  | [**Python**](https://www.python.org)                               | `python` / `python3` / `Python`                   | `https://www.python.org`                       |
  | [**fastlane**](https://fastlane.tools)                             | `fastlane`                                        | `https://fastlane.tools`                       |
  | [**MySQL**](https://www.mysql.com)                                 | `mysql` / `MySQL`                                 | `https://www.mysql.com`                        |
  | [**Hugo**](https://gohugo.io)                                      | `hugo` / `Hugo`                                   | `https://gohugo.io`                            |
  | [**OpenJDK**](https://openjdk.org)                                 | `openjdk` / `OpenJDK`                             | `https://openjdk.org`                          |
  | [**yt-dlp**](https://ytdlp.online)                                 | `yt-dlp`                                          | `https://ytdlp.online`                         |
  | [**FFmpeg**](https://ffmpeg.org)                                   | `ffmpeg` / `FFmpeg`                               | `https://ffmpeg.org`                           |
  | [**go-task**](https://formulae.brew.sh/formula/go-task)            | `go-task` / `tap/go-task` / `go-task/tap/go-task` | `https://formulae.brew.sh/formula/go-task`     |
  | [**uv**](https://formulae.brew.sh/formula/uv)                      | `uv`                                              | `https://formulae.brew.sh/formula/uv`          |
  | [**fzf**](https://formulae.brew.sh/formula/fzf)                    | `fzf`                                             | `https://formulae.brew.sh/formula/fzf`         |
  | [**lazygit**](https://lazygit.dev)                                 | `lazygit`                                         | `https://lazygit.dev`                          |
  | [**dufs**](https://formulae.brew.sh/formula/dufs)                  | `dufs`                                            | `https://formulae.brew.sh/formula/dufs`        |
  | [**Codex**](https://openai.com/codex)                              | `codex` / `Codex`                                 | `https://openai.com/codex`                     |
  | [**Mermaid**](https://mermaid.js.org)                              | `Mermaid`                                         | `https://mermaid.js.org`                       |
  | [**Hammerspoon**](https://www.hammerspoon.org)                     | `Hammerspoon`                                     | `https://www.hammerspoon.org`                  |
  | [**VLC**](https://www.videolan.org/vlc)                            | `VLC`                                             | `https://www.videolan.org/vlc`                 |
  | [**trex**](https://formulae.brew.sh/cask/trex)                     | `trex`                                            | `https://formulae.brew.sh/cask/trex`           |
  | [**Visual Studio Code**](https://code.visualstudio.com)            | `Visual Studio Code` / `VS Code` / `code`         | `https://code.visualstudio.com`                |
  | [**Android Studio**](https://developer.android.com/studio?hl=zh-c) | `Android Studio`                                  | `https://developer.android.com/studio?hl=zh-c` |
  | [**GitHub**](https://github.com)                                   | `GitHub` / `github`                               | `https://github.com`                           |
  | [**Xcode**](https://developer.apple.com/xcode)                     | `Xcode`                                           | `https://developer.apple.com/xcode`            |
  | [**pip**](https://pip.pypa.io)                                     | `pip`                                             | `https://pip.pypa.io`                          |
  | [**JobsKits**](https://github.com/JobsKits)                        | `JobsKits`                                        | `https://github.com/JobsKits`                  |

### 4.4、README 固定内容

- 每个可双击脚本目录优先放同名脚本和 `README.md`。
- README 用中文说明，适合用户双击前先看懂：用途、适用场景、执行前检查、操作流程、是否有风险、日志位置、常见问题。
- 技术文档优先包含这些块，按需要取舍：`前言`、`适用场景`、`运行方式`、`执行前检查`、`脚本执行命令`、`流程图`、`日志文件`、`常见问题`、`风险说明`、`未执行声明`。

## 五、[**CocoaPods**](https://cocoapods.org/) Podspec 文件（`*.podspec`） <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 5.1、适用范围

- 本规范来自 `/Users/jobs/Documents/JobsOCBaseConfigDemo/JobsByPods` 下 69 个 `*.podspec` 的现有写法。
- 适用于 Jobs 本地管理的 [**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) Pods、`Extra` 扩展 Pods、聚合 Pods，以及 `ManualByOCPods@Pods` 下手动托管的第三方 Pods。
- 新增或升级 podspec 时，先看同类 Pod 的现有写法，再按本规范收口。不要凭空换一套 [**CocoaPods**](https://cocoapods.org/) 风格。

### 5.2、整体结构

- 自研 Pod / Extra Pod 优先使用同目录 `JobsPodspecKit.rb`：

  ```ruby
  require_relative 'JobsPodspecKit'

  Pod::Spec.new do |spec|
    support_context = JobsPodspecKitForPodName.build_support_context(
      podspec_dir: File.expand_path(File.dirname(__FILE__)),
      support_dir: 'Support',
      support_dependencies: []
    )

    # spec 元信息
    # source / platform / subspec / dependencies / xcconfig
  end
  ```

- 字段顺序优先保持稳定：`require_relative`、`support_context`、`name`、`version`、`summary`、`description`、`homepage`、`license`、`author`、`platform`、`requires_arc`、`source`、`default_subspecs`、根入口文件、`Support` / `Core`、`exclude_files`、`frameworks`、`dependency`、`xcconfig`。
- 字段对齐按现有风格即可：

  ```ruby
  spec.name             = 'JobsBaseUI'
  spec.version          = '1.0.0'
  spec.summary          = 'Base UI component library for Jobs projects.'
  spec.platform         = :ios, '12.0'
  spec.requires_arc     = true
  spec.source           = { :path => '.' }
  spec.default_subspecs = 'Core'
  ```

### 5.3、基础信息与 source

- 自研 Pod 的 `homepage` 可以使用 `https://example.local/PodName`；已经有真实 Git 地址的 Pod 保留真实地址。
- 自研 Pod 作者默认：`spec.author = { 'Jobs' => 'lg295060456@gmail.com' }`。
- 第三方 Manual Pod 保留原作者、原 homepage、原 license；只做本地托管适配，不抹掉来源信息。
- iOS 最低版本默认：`spec.platform = :ios, '12.0'`。
- Objective-C Pod 默认：`spec.requires_arc = true`。
- 本地管理的 Pod 默认：`spec.source = { :path => '.' }`。
- 需要模拟远程 tag 或聚合仓库时，才使用：`spec.source = { :git => "file://#{__dir__}", :tag => spec.version.to_s }`。
- 第三方 Manual Pod 如果保留上游源码声明，可以继续使用：`spec.source = { :git => 'https://github.com/owner/repo.git', :tag => spec.version.to_s }`。

### 5.4、入口头文件 / Core / Support

- 有根入口头文件时，根层只暴露入口头：

  ```ruby
  spec.source_files        = 'PodName.h'
  spec.public_header_files = 'PodName.h'
  ```

- 默认业务代码进入 `Core`：

  ```ruby
  spec.default_subspecs = 'Core'

  spec.subspec 'Core' do |ss|
    JobsPodspecKitForPodName.add_dynamic_support_dependencies(ss, spec, support_context)

    ss.source_files        = 'Core/**/*.{h,m,mm}'
    ss.public_header_files = 'Core/**/*.h'
    ss.resources           = 'Core/**/*.{png,jpg,jpeg,gif,webp,xcassets,bundle,json,plist,xib,storyboard,strings,stringsdict}'
  end
  ```

- 有 `Support` 目录时，自研 Pod 优先用 `JobsPodspecKitForPodName.add_support_subspec(spec, support_context)` 镜像真实目录。
- `Core` 依赖 `Support` 时，优先使用 `JobsPodspecKitForPodName.add_dynamic_support_dependencies(ss, spec, support_context)`。
- 如果某个 Support 子路径必须显式依赖，可以只补最小必要项，例如 `ss.dependency 'JobsOCDefs/Support/UIKit'`。

### 5.5、资源、排除与依赖

- 源码扩展默认覆盖 `h,m,mm`。
- 资源扩展默认覆盖 `png,jpg,jpeg,gif,webp,svg,pdf,json,plist,bundle,xib,nib,storyboard,xcassets,strings,stringsdict,ttf,otf,mp4,aiff`。
- `source_files` 只匹配源码和头文件；图片、xib、bundle、json、plist 等进入 `resources`，不要混在源码 glob 里。
- 自研 Pod 优先调用 `JobsPodspecKitForPodName.apply_standard_exclude_files(spec)`。
- Manual Pod 没有 `JobsPodspecKit` 时，要手写完整排除清单，至少覆盖 macOS 垃圾文件、Git / SVN、[**CocoaPods**](https://cocoapods.org/)、[**Xcode**](https://developer.apple.com/xcode/)、Demo / Example / Test、文档截图、CI / 临时 / 压缩包。
- `frameworks` 使用数组，按现有 Jobs 风格多行写。
- 依赖优先一行一个，放在 `frameworks` 后或对应 subspec 内。有版本约束时使用 [**CocoaPods**](https://cocoapods.org/) 原生写法，例如 `spec.dependency 'lottie-ios', '~> 2.5.3'`。
- 聚合 Pod 依赖很多时，可以先定义 `common_dependencies`，再用 lambda 统一添加。

### 5.6、xcconfig 与校验

- 自研 Pod 默认使用 `JobsPodspecKitForPodName.apply_standard_xcconfig(spec)`。
- 标准配置应包含 `DEFINES_MODULE`、`HEADER_SEARCH_PATHS`、`CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES`。
- 只有确实需要链接 Objective-C Category 时，才补 `'OTHER_LDFLAGS' => '$(inherited) -ObjC'`。
- 如果某个 Pod 头文件搜索路径必须收窄，可以像 `JobsAPIs` 一样显式指定 `Core` / `Support`，不要无脑扩大。
- podspec 注释同样精简扼要，只解释目录策略、动态 Support、风险依赖、特殊 xcconfig。
- 需要校验时优先使用：

  ```shell
  pod lib lint PodName.podspec --allow-warnings --verbose
  ```

- 本地集成排查优先：

  ```shell
  pod install --no-repo-update
  ```

- 如果当前机器环境不适合实际执行 `pod`，至少做 [**Ruby**](https://www.ruby-lang.org) 语法检查：

  ```shell
  ruby -c PodName.podspec
  ```

- 修改 podspec 后要重点检查：`spec.name` 是否和文件名一致、入口头是否真实存在、`Core` / `Support` glob 是否命中、依赖是否形成循环、资源是否被错误放进 `source_files`。

## 六、OC 写作规范 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

<!--
后续补充 Objective-C 规范时，在这里继续写：

- 项目结构
- 命名规则
- Category 约定
- 注释风格
- 宏 / 常量 / 枚举
- UIKit 使用边界
- 线程、安全、内存管理
- 单元测试 / UI 测试
-->

## 七、[**Swift**](https://www.swift.org/) 写作规范 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

<!--
后续补充 Swift 规范时，在这里继续写：

- Swift 命名规则
- Extension 约定
- UIKit / SwiftUI 使用边界
- Codable / Result / async-await 使用方式
- 访问控制
- 错误处理
- 单元测试 / UI 测试
-->

## 八、[**Python**](https://www.python.org/) 写作规范 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

<!--
后续补充 Python 规范时，在这里继续写：

- 脚本入口
- argparse / click 等命令行约定
- pathlib / subprocess 使用边界
- 日志与异常处理
- 虚拟环境与依赖管理
- 格式化 / lint / 测试
-->

## 九、[**Dart**](https://dart.dev) / [**Flutter**](https://flutter.dev/) 写作规范 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

<!--
后续补充 Dart / Flutter 规范时，在这里继续写：

- Dart 命名与目录结构
- 页面 / Widget 拆分
- 状态管理
- 路由
- 资源管理
- iOS / Android 打包脚本
- CocoaPods / Gradle / Flutter SDK 版本处理
- 代码生成与自动化脚本约定
-->

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
