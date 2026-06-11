---
name: jobs-macos-shell
description: 当任务涉及 MacOS 原生 Shell、zsh、.sh、.command、Homebrew、自检、批量脚本、压缩包输出、Sourcetree 自定义动作脚本时使用。
---

# Jobs MacOS Shell 脚本规范

> 本技能由 `💻JobsCodexConfigs/AGENTS.md` 拆分而来，保留原有 Jobs 工作规范。只有当前任务命中本技能描述时才加载本文件，避免把所有细则长期塞进全局上下文。

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


### 2.7、脚本运行策略与自检定义

- 所有可独立运行的脚本，执行真实业务逻辑前必须先打印自述说明，再等待用户回车确认；用户未回车前不得继续往下执行。`.command` 优先读取同目录 `README.md`，没有 `README.md` 时必须输出内置说明。

  ```shell
  show_script_intro_and_wait() {
    # 执行前展示脚本用途，让用户确认不是误触。
    clear
    highlight_echo "============================== 脚本自述 =============================="
    note_echo "当前脚本：${SCRIPT_PATH}"
    note_echo "脚本用途：这里写清楚当前脚本准备做什么、会影响哪些文件或环境。"
    warn_echo "继续前请确认已经理解脚本影响范围；按 Ctrl+C 可以取消。"
    highlight_echo "======================================================================="
    echo ""
    read -r "?👉 确认继续执行请按回车；按 Ctrl+C 取消：" _
  }
  ```

- 新写脚本时优先参考 [**JobsDocs Shell 脚本代码片段**](https://github.com/JobsKits/JobsDocs/blob/main/🔥Shell脚本代码片段.md/Shell脚本代码片段.md)，但不要机械复制；必须结合当前脚本职责做最小必要改造。
- 每个方法 / 函数都要写简短注释，说明这段函数负责什么；注释服务维护，不写无意义的逐行翻译。
- `main` 是唯一流程收口点，里面同样要写清楚主流程编排注释，最后固定：

  ```shell
  main() {
    # 主流程统一收口：先展示自述，再做环境检查，最后执行真实业务逻辑。
    show_script_intro_and_wait
    check_environment
    run_business
  }

  main "$@"
  ```

- 自检类脚本的定义统一为：检测目标是否存在；如果已经存在，则进入升级 / 更新逻辑；如果没有检测到已安装，则安装最新版本。
- 自检、安装、升级都必须先检查再执行，并遵守交互确认：普通动作不能默认执行，危险动作必须输入 `YES`。
- 新写或升级脚本继续统一使用 `#!/bin/zsh`，不要退回 `#!/bin/bash`；除非目标环境明确不是 MacOS / zsh。


### 2.8、Sourcetree 自定义动作脚本兼容

- `Sourcetree` 自定义动作运行 `.command` 时，环境可能和系统终端双击运行不同：`TERM` 可能为空、`$0` 可能只是脚本名而不是绝对路径、标准输入可能不可交互、输出窗口可能不解析 ANSI 彩色码。
- 写 `SourceTree.sh` 目录下的脚本时，必须显式探测运行环境；只有确认处在 `Sourcetree` 或非完整终端环境时才降级，不要影响用户双击脚本后在系统终端里的正常交互体验。
- `SCRIPT_DIR` 不能只依赖 `dirname "$0"`；当 `$0` 不是绝对路径时，要按脚本名从 `~/SourceTree.sh/脚本名/脚本名` 和 `/Users/jobs/Documents/Github/JobsGenesis/SourceTree.sh/脚本名/脚本名` 兜底找回真实脚本目录，确保能读取同目录 `README.md`，不能退化成 `/README.md`。
- 调用 `clear` 前必须确认是完整终端，例如同时满足 `-t 1`、`TERM` 非空且不是 `dumb`，并且不是 `Sourcetree` 瘦身环境；否则跳过 `clear`，避免出现 `TERM environment variable not set.`。
- 彩色日志必须支持纯文本降级：如果检测到 `Sourcetree`、非 TTY、`TERM=dumb` 或用户设置 `NO_COLOR`，不要输出 `\033` 这类 ANSI 转义码，避免日志里出现 `[0m` 乱码。
- README 防误触在系统终端里继续阻塞等待回车；在 `Sourcetree` 非交互输入下不要卡住流程，应打印“已跳过回车等待”的说明后继续。
- `Sourcetree` 脚本运行时展示的自述必须写在脚本内部，例如 `show_readme_and_wait` / `show_script_intro_and_wait` 函数直接打印脚本名称、用途、运行入口、环境策略、风险提示和日志路径；不能在运行时 `cat`、拼接或依赖外部 `README.md`。同目录 `README.md` 只作为静态文档保留，不作为脚本运行时自述来源。
- `Sourcetree` 脚本如果会递归处理工程目录，默认跳过 `.git`、`Pods`、`.dart_tool`、`build`、`DerivedData`，并在最后输出总数、失败数和日志路径；只要有子任务失败，脚本最终也要返回失败状态，方便 `Sourcetree` 判断执行结果。
