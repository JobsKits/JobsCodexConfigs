#!/bin/zsh
setopt NO_NOMATCH

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
SCRIPT_PATH="${SCRIPT_DIR}/$(basename -- "$0")"
SCRIPT_BASENAME=$(basename "$0" | sed 's/\.[^.]*$//')
LOG_FILE="/tmp/${SCRIPT_BASENAME}.log"
: > "$LOG_FILE"

# 解析并返回后续流程需要的目标信息。
resolve_toolkit_dir() {
  # 脚本推荐位于：💻JobsCodexConfigs/【MacOS】Codex配置注入替换工具.command/脚本文件
  # 因此需要从脚本所在目录向上查找真正的 💻JobsCodexConfigs 根目录。
  local candidate_dir="$SCRIPT_DIR"
  local scan_depth=0

  while [[ -n "$candidate_dir" && "$candidate_dir" != "/" && "$scan_depth" -lt 8 ]]; do
    if [[ -f "${candidate_dir}/AGENTS.md" && -d "${candidate_dir}/skills" ]]; then
      cd "$candidate_dir" && pwd
      return 0
    fi

    candidate_dir="$(dirname "$candidate_dir")"
    scan_depth=$((scan_depth + 1))
  done

  print -r -- "$SCRIPT_DIR"
}

TOOLKIT_DIR="$(resolve_toolkit_dir)"
GLOBAL_AGENTS_PATH="${TOOLKIT_DIR}/AGENTS.md"
SKILLS_SOURCE_DIR="${TOOLKIT_DIR}/skills"
TARGET_CODEX_DIR="${TARGET_CODEX_DIR:-${HOME}/.codex}"
TARGET_CODEX_CONFIG="${TARGET_CODEX_CONFIG:-${TARGET_CODEX_DIR}/config.toml}"
TARGET_SKILLS_DIR="${TARGET_SKILLS_DIR:-${HOME}/.agents/skills}"
BREW_BIN=""
TEMP_WORK_DIRS=()
DEPLOYED_SKILL_NAMES=()

# 按当前输出级别记录终端信息，并同步写入脚本日志。
log()            { echo -e "$1" | tee -a "$LOG_FILE"; }
# 按当前输出级别记录终端信息，并同步写入脚本日志。
color_echo()     { log "\033[1;32m$1\033[0m"; }
# 按当前输出级别记录终端信息，并同步写入脚本日志。
info_echo()      { log "\033[1;34mℹ $1\033[0m"; }
# 按当前输出级别记录终端信息，并同步写入脚本日志。
success_echo()   { log "\033[1;32m✔ $1\033[0m"; }
# 按当前输出级别记录终端信息，并同步写入脚本日志。
warn_echo()      { log "\033[1;33m⚠ $1\033[0m"; }
# 按当前输出级别记录终端信息，并同步写入脚本日志。
warm_echo()      { log "\033[1;33m$1\033[0m"; }
# 按当前输出级别记录终端信息，并同步写入脚本日志。
note_echo()      { log "\033[1;35m➤ $1\033[0m"; }
# 按当前输出级别记录终端信息，并同步写入脚本日志。
error_echo()     { log "\033[1;31m✖ $1\033[0m"; }
# 按当前输出级别记录终端信息，并同步写入脚本日志。
err_echo()       { log "\033[1;31m$1\033[0m"; }
# 按当前输出级别记录终端信息，并同步写入脚本日志。
debug_echo()     { log "\033[1;35m🐞 $1\033[0m"; }
# 按当前输出级别记录终端信息，并同步写入脚本日志。
highlight_echo() { log "\033[1;36m🔹 $1\033[0m"; }
# 按当前输出级别记录终端信息，并同步写入脚本日志。
gray_echo()      { log "\033[0;90m$1\033[0m"; }
# 按当前输出级别记录终端信息，并同步写入脚本日志。
bold_echo()      { log "\033[1m$1\033[0m"; }
# 按当前输出级别记录终端信息，并同步写入脚本日志。
underline_echo() { log "\033[4m$1\033[0m"; }

# 执行已经拆分完成的独立业务步骤。
run_command() {
  info_echo "执行：$*"
  "$@" 2>&1 | tee -a "$LOG_FILE"
  local exit_code=${pipestatus[1]}
  if [[ "$exit_code" -ne 0 ]]; then
    error_echo "命令执行失败，退出码：${exit_code}"
  fi
  return "$exit_code"
}

# 封装 register_temp_dir 对应的独立处理逻辑。
register_temp_dir() {
  local dir="$1"
  [[ -n "$dir" && -d "$dir" ]] && TEMP_WORK_DIRS+=("$dir")
}

# 执行对应的清理操作，并保留必要的安全检查。
cleanup_temp_dirs() {
  local dir=""
  for dir in "${TEMP_WORK_DIRS[@]}"; do
    if [[ -n "$dir" && -d "$dir" && "$dir" == /tmp/* ]]; then
      /bin/rm -rf -- "$dir" >/dev/null 2>&1 || true
    fi
  done
}

trap cleanup_temp_dirs EXIT INT TERM

# 展示脚本用途和影响范围，并在执行前等待用户确认。
show_readme_and_wait() {
  local readme_path="${SCRIPT_DIR}/README.md"
  if [[ ! -f "$readme_path" && -f "${TOOLKIT_DIR}/README.md" ]]; then
    readme_path="${TOOLKIT_DIR}/README.md"
  fi

  clear
  if [[ -f "$readme_path" ]]; then
    highlight_echo "============================== README.md =============================="
    cat "$readme_path" | tee -a "$LOG_FILE"
    highlight_echo "======================================================================="
  else
    warn_echo "未找到 README.md，继续执行内置流程说明。"
  fi
  echo ""
  local answer=""
  read -r "?👉 已阅读自述文件，按回车继续执行；按 Ctrl+C 取消：" answer
}

# 收集并校验用户输入，决定后续执行路径。
ask_any_to_run() {
  local message="$1"
  local answer=""
  read -r "?${message}（直接回车跳过；输入任意字符后回车执行）：" answer
  [[ -n "$answer" ]]
}

# 解析并返回后续流程需要的目标信息。
get_cpu_arch() {
  [[ "$(uname -m)" == "arm64" ]] && echo "arm64" || echo "x86_64"
}

# 解析并返回后续流程需要的目标信息。
find_first_app_path() {
  # 按 MacOS 固定应用目录查找图形化 App。
  local app_path=""
  for app_path in "$@"; do
    if [[ -d "$app_path" ]]; then
      print -r -- "$app_path"
      return 0
    fi
  done
  return 1
}

# 解析并返回后续流程需要的目标信息。
find_brew_path() {
  if command -v brew >/dev/null 2>&1; then
    command -v brew
    return 0
  fi

  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    echo "/opt/homebrew/bin/brew"
    return 0
  fi

  if [[ -x "/usr/local/bin/brew" ]]; then
    echo "/usr/local/bin/brew"
    return 0
  fi

  return 1
}

# 检查当前运行条件是否满足后续流程要求。
ensure_homebrew_shellenv() {
  local brew_path="$1"
  local shellenv_cmd=""
  shellenv_cmd="$($brew_path shellenv 2>/dev/null)"

  if [[ -z "$shellenv_cmd" ]]; then
    warn_echo "无法获取 Homebrew shellenv，跳过写入 shell 配置。"
    return 0
  fi

  eval "$shellenv_cmd"

  local zprofile_path="${HOME}/.zprofile"
  local header="# >>> Jobs Homebrew shellenv >>>"
  local footer="# <<< Jobs Homebrew shellenv <<<"
  if [[ ! -f "$zprofile_path" ]] || ! grep -Fq "$header" "$zprofile_path"; then
    {
      echo ""
      echo "$header"
      echo "eval \"\$(${brew_path} shellenv)\""
      echo "$footer"
    } >> "$zprofile_path"
    success_echo "已写入 Homebrew shellenv 到：${zprofile_path}"
  else
    gray_echo "已存在 Homebrew shellenv 配置块，跳过重复写入。"
  fi
}

# 执行对应的环境配置或同步处理。
install_homebrew() {
  warn_echo "未检测到 Homebrew。"
  if ! ask_any_to_run "是否安装 Homebrew"; then
    error_echo "缺少 Homebrew，无法继续安装 fzf / Codex。"
    exit 1
  fi

  local installer_path=""
  installer_path="$(mktemp "/tmp/homebrew_install.XXXXXX.sh")"
  info_echo "开始下载 Homebrew 安装脚本：${installer_path}"
  if ! run_command /usr/bin/curl -fsSL "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh" -o "$installer_path"; then
    rm -f "$installer_path"
    error_echo "Homebrew 安装脚本下载失败，请检查网络后重试。"
    exit 1
  fi

  info_echo "开始安装 Homebrew。"
  if ! run_command /bin/bash "$installer_path"; then
    rm -f "$installer_path"
    error_echo "Homebrew 安装失败，请检查网络、CLT 或权限后重试。"
    exit 1
  fi
  rm -f "$installer_path"
}

# 检查当前运行条件是否满足后续流程要求。
ensure_homebrew() {
  local arch="$(get_cpu_arch)"
  info_echo "当前芯片架构：${arch}"

  if ! BREW_BIN="$(find_brew_path)"; then
    install_homebrew
    if ! BREW_BIN="$(find_brew_path)"; then
      error_echo "安装后仍未找到 brew，请重新打开终端后再执行本脚本。"
      exit 1
    fi
  fi

  success_echo "已检测到 Homebrew：${BREW_BIN}"
  ensure_homebrew_shellenv "$BREW_BIN"
  run_command "$BREW_BIN" -v || true

  if ask_any_to_run "是否执行 Homebrew 自检与升级：brew update && brew upgrade && brew cleanup && brew doctor && brew -v"; then
    run_command "$BREW_BIN" update || exit 1
    run_command "$BREW_BIN" upgrade || exit 1
    run_command "$BREW_BIN" cleanup || exit 1
    run_command "$BREW_BIN" doctor || true
    run_command "$BREW_BIN" -v || true
  else
    gray_echo "已跳过 Homebrew 升级 / 自检。"
  fi
}

# 检查当前运行条件是否满足后续流程要求。
check_fzf_health() {
  # fzf 是 Codex++ 启动选择的交互基础，这里做一次轻量健康体检。
  local fzf_path=""
  fzf_path="$(command -v fzf 2>/dev/null)"
  if [[ -z "$fzf_path" ]]; then
    error_echo "fzf 不在 PATH 中。"
    return 1
  fi

  success_echo "已检测到 fzf：${fzf_path}"
  if ! "$fzf_path" --version >/tmp/fzf_health.$$ 2>&1; then
    cat /tmp/fzf_health.$$ | tee -a "$LOG_FILE" >/dev/null 2>&1 || true
    rm -f /tmp/fzf_health.$$
    error_echo "fzf --version 执行失败，fzf 当前不可用。"
    return 1
  fi

  local version_text=""
  version_text="$(cat /tmp/fzf_health.$$ 2>/dev/null | head -n 1)"
  rm -f /tmp/fzf_health.$$
  gray_echo "fzf 版本：${version_text}"

  if [[ ! -t 0 || ! -t 1 ]]; then
    warn_echo "当前终端不是完整 TTY，fzf 交互菜单可能无法正常显示；建议双击 .command 或在 Terminal 中运行。"
  fi
  return 0
}

# 检查当前运行条件是否满足后续流程要求。
ensure_fzf() {
  if command -v fzf >/dev/null 2>&1; then
    check_fzf_health || exit 1
    return 0
  fi

  warn_echo "未检测到 fzf。Codex++ 存在时，脚本需要 fzf 菜单选择启动入口。"
  if ! ask_any_to_run "是否执行 brew install fzf"; then
    error_echo "缺少 fzf，无法继续执行 Codex++ 启动入口选择。"
    exit 1
  fi

  run_command "$BREW_BIN" install fzf || exit 1
  check_fzf_health || {
    error_echo "fzf 安装后仍不可用，请重新打开终端或检查 Homebrew PATH。"
    exit 1
  }
}

# 检查当前运行条件是否满足后续流程要求。
is_cask_installed() {
  local cask_name="$1"
  "$BREW_BIN" list --cask "$cask_name" >/dev/null 2>&1
}

# 检查当前运行条件是否满足后续流程要求。
ensure_codex() {
  # Codex 可能来自 Homebrew Cask，也可能是手动安装的 /Applications/Codex.app；这里以实际可启动入口为准。
  local required_casks=(codex-app codex)
  local missing_casks=()
  local installed_casks=()

  for cask_name in "${required_casks[@]}"; do
    if is_cask_installed "$cask_name"; then
      installed_casks+=("$cask_name")
      success_echo "已检测到 Codex Cask：${cask_name}"
    else
      missing_casks+=("$cask_name")
      warn_echo "未检测到 Codex Cask：${cask_name}"
    fi
  done

  local codex_app=""
  local codex_cli=""
  codex_app="$(find_first_app_path "/Applications/Codex.app" "${HOME}/Applications/Codex.app")" || true
  codex_cli="$(command -v codex 2>/dev/null)" || true

  if [[ -n "$codex_app" ]]; then
    success_echo "已检测到 Codex App：${codex_app}"
  else
    warn_echo "未在 /Applications 或 ~/Applications 检测到 Codex.app。"
  fi

  if [[ -n "$codex_cli" ]]; then
    success_echo "已检测到 codex CLI：${codex_cli}"
  else
    warn_echo "未检测到 codex CLI；如果你只使用 Codex App，可忽略此提示。"
  fi

  if [[ -z "$codex_app" && -z "$codex_cli" ]]; then
    local missing_text="${(j: :)missing_casks}"
    if [[ -z "$missing_text" ]]; then
      missing_text="codex-app codex"
    fi

    if ! ask_any_to_run "未发现 Codex App / CLI，是否尝试安装 Codex Cask：${missing_text}"; then
      error_echo "未检测到可用 Codex，部署配置没有意义，已终止。"
      exit 1
    fi

    if (( ${#missing_casks[@]} == 0 )); then
      missing_casks=("${required_casks[@]}")
    fi

    local cask_name=""
    for cask_name in "${missing_casks[@]}"; do
      run_command "$BREW_BIN" install --cask "$cask_name" || exit 1
    done
  elif (( ${#installed_casks[@]} > 0 )); then
    if ask_any_to_run "是否执行 Codex 自检与升级：brew update && brew upgrade --cask ${(j: :)installed_casks} && brew cleanup && brew doctor && brew info --cask ${(j: :)installed_casks}"; then
      run_command "$BREW_BIN" update || exit 1
      local cask_name=""
      for cask_name in "${installed_casks[@]}"; do
        run_command "$BREW_BIN" upgrade --cask "$cask_name" || true
      done
      run_command "$BREW_BIN" cleanup || exit 1
      run_command "$BREW_BIN" doctor || true
      run_command "$BREW_BIN" info --cask "${installed_casks[@]}" || true
    else
      gray_echo "已跳过 Codex 升级 / 自检。"
    fi
  else
    gray_echo "Codex 不是通过本脚本识别的 Homebrew Cask 安装，跳过 Cask 升级。"
  fi
}

# 检查当前运行条件是否满足后续流程要求。
validate_toolkit_layout() {
  if [[ ! -f "$GLOBAL_AGENTS_PATH" ]]; then
    error_echo "未找到全局 AGENTS.md：${GLOBAL_AGENTS_PATH}"
    exit 1
  fi

  if [[ ! -d "$SKILLS_SOURCE_DIR" ]]; then
    error_echo "未找到 Skills 源目录：${SKILLS_SOURCE_DIR}"
    exit 1
  fi

  local first_skill=""
  first_skill="$(find "$SKILLS_SOURCE_DIR" -mindepth 2 -maxdepth 2 -name 'SKILL.md' -print -quit 2>/dev/null)"
  if [[ -z "$first_skill" ]]; then
    error_echo "Skills 源目录中没有发现任何 SKILL.md：${SKILLS_SOURCE_DIR}"
    exit 1
  fi

  success_echo "工具包目录检查通过。"
  gray_echo "工具包根目录：${TOOLKIT_DIR}"
  gray_echo "全局 AGENTS 源：${GLOBAL_AGENTS_PATH}"
  gray_echo "Skills 源目录：${SKILLS_SOURCE_DIR}"
  gray_echo "目标 .codex：${TARGET_CODEX_DIR}"
  gray_echo "目标 AGENTS：${TARGET_CODEX_DIR}/AGENTS.md"
  gray_echo "目标 config.toml：${TARGET_CODEX_CONFIG}"
  gray_echo "目标 Skills：${TARGET_SKILLS_DIR}"
}

# 封装 stop_codex_runtime 对应的独立处理逻辑。
stop_codex_runtime() {
  local message="$1"
  info_echo "$message"

  /usr/bin/osascript -e 'tell application "Codex" to quit' >/dev/null 2>&1 || true
  sleep 1

  local pids=()
  local process_name=""
  for process_name in "Codex" "codex"; do
    while IFS= read -r pid; do
      [[ -n "$pid" ]] && pids+=("$pid")
    done < <(/usr/bin/pgrep -x "$process_name" 2>/dev/null || true)
  done

  if (( ${#pids[@]} == 0 )); then
    gray_echo "未发现仍在运行的 Codex 进程。"
    return 0
  fi

  for pid in "${pids[@]}"; do
    [[ "$pid" == "$$" ]] && continue
    /bin/kill -TERM "$pid" 2>/dev/null || true
  done

  sleep 2

  for pid in "${pids[@]}"; do
    [[ "$pid" == "$$" ]] && continue
    if /bin/kill -0 "$pid" 2>/dev/null; then
      warn_echo "进程 ${pid} 未正常退出，执行强制终止。"
      /bin/kill -KILL "$pid" 2>/dev/null || true
    fi
  done

  success_echo "Codex 运行态已停止。"
}

# 封装 deploy_global_agents 对应的独立处理逻辑。
deploy_global_agents() {
  # 单向部署本仓库 AGENTS.md 到 Codex 全局指导文件位置。
  # 这里不替换整个 ~/.codex，只创建目录并覆盖 AGENTS.md。
  if [[ -e "$TARGET_CODEX_DIR" && ! -d "$TARGET_CODEX_DIR" ]]; then
    error_echo "目标 .codex 路径已存在但不是目录：${TARGET_CODEX_DIR}"
    exit 1
  fi

  if [[ ! -d "$TARGET_CODEX_DIR" ]]; then
    info_echo "目标 .codex 不存在，创建目录：${TARGET_CODEX_DIR}"
    if ! run_command /bin/mkdir -p "$TARGET_CODEX_DIR"; then
      error_echo "创建目标 .codex 目录失败：${TARGET_CODEX_DIR}"
      exit 1
    fi
  fi

  if [[ ! -w "$TARGET_CODEX_DIR" ]]; then
    error_echo "目标 .codex 目录不可写：${TARGET_CODEX_DIR}"
    exit 1
  fi

  info_echo "开始覆盖写入 Codex 全局 AGENTS.md。"
  gray_echo "来源：${GLOBAL_AGENTS_PATH}"
  gray_echo "目标：${TARGET_CODEX_DIR}/AGENTS.md"

  if ! run_command /bin/cp -f "$GLOBAL_AGENTS_PATH" "${TARGET_CODEX_DIR}/AGENTS.md"; then
    error_echo "覆盖 AGENTS.md 失败。"
    exit 1
  fi

  success_echo "全局 AGENTS.md 部署完成。"
}

# 封装 deploy_user_skills 对应的独立处理逻辑。
deploy_user_skills() {
  # 单向部署本仓库 skills 到 Codex 用户级 Skills 目录；不从系统位置回写到仓库。
  if [[ ! -d "$SKILLS_SOURCE_DIR" ]]; then
    error_echo "Skills 源目录不存在，禁止继续：${SKILLS_SOURCE_DIR}"
    exit 1
  fi

  if [[ -e "$TARGET_SKILLS_DIR" && ! -d "$TARGET_SKILLS_DIR" ]]; then
    error_echo "目标 Skills 路径已存在但不是目录：${TARGET_SKILLS_DIR}"
    exit 1
  fi

  mkdir -p "$TARGET_SKILLS_DIR" || {
    error_echo "创建目标 Skills 目录失败：${TARGET_SKILLS_DIR}"
    exit 1
  }

  info_echo "开始部署 Jobs Skills。"
  gray_echo "来源：${SKILLS_SOURCE_DIR}"
  gray_echo "目标：${TARGET_SKILLS_DIR}"

  local deployed_count=0
  local source_skill_dir=""
  while IFS= read -r -d '' source_skill_dir; do
    local skill_name="$(basename "$source_skill_dir")"
    local source_skill_file="${source_skill_dir}/SKILL.md"
    local target_skill_dir="${TARGET_SKILLS_DIR}/${skill_name}"

    if [[ ! -f "$source_skill_file" ]]; then
      warn_echo "跳过没有 SKILL.md 的目录：${source_skill_dir}"
      continue
    fi

    if [[ -e "$target_skill_dir" ]]; then
      warn_echo "替换同名 Skill：${target_skill_dir}"
      if ! run_command /bin/rm -rf -- "$target_skill_dir"; then
        error_echo "清理旧 Skill 失败：${target_skill_dir}"
        exit 1
      fi
    fi

    if ! run_command /usr/bin/ditto "$source_skill_dir" "$target_skill_dir"; then
      error_echo "部署 Skill 失败：${skill_name}"
      exit 1
    fi

    if [[ ! -f "${target_skill_dir}/SKILL.md" ]]; then
      error_echo "部署后缺少 SKILL.md：${target_skill_dir}"
      exit 1
    fi

    DEPLOYED_SKILL_NAMES+=("$skill_name")
    deployed_count=$((deployed_count + 1))
    success_echo "已部署 Skill：${skill_name}"
  done < <(find "$SKILLS_SOURCE_DIR" -mindepth 1 -maxdepth 1 -type d -print0)

  if (( deployed_count == 0 )); then
    error_echo "没有部署任何 Skill，请检查：${SKILLS_SOURCE_DIR}"
    exit 1
  fi

  success_echo "Jobs Skills 部署完成，共 ${deployed_count} 个。"
}


# 封装 toml_escape_string 对应的独立处理逻辑。
toml_escape_string() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  print -r -- "$value"
}

# 执行对应的环境配置或同步处理。
update_codex_skills_config() {
  # Codex 官方会扫描 $HOME/.agents/skills；Codex++ 管理器的 Skills 页签通常读取 ~/.codex/config.toml 中的 [[skills.config]] 条目。
  # 因此这里在不回写仓库、不替换整个 ~/.codex 的前提下，追加一个受控配置块，让 Codex++ 管理器也能看到这些 Jobs Skills。
  if (( ${#DEPLOYED_SKILL_NAMES[@]} == 0 )); then
    warn_echo "没有已部署的 Skill，跳过 config.toml Skills 注册。"
    return 0
  fi

  if [[ -e "$TARGET_CODEX_CONFIG" && ! -f "$TARGET_CODEX_CONFIG" ]]; then
    error_echo "目标 config.toml 路径已存在但不是文件：${TARGET_CODEX_CONFIG}"
    exit 1
  fi

  mkdir -p "$(dirname "$TARGET_CODEX_CONFIG")" || {
    error_echo "创建 config.toml 所在目录失败：$(dirname "$TARGET_CODEX_CONFIG")"
    exit 1
  }

  [[ -f "$TARGET_CODEX_CONFIG" ]] || : > "$TARGET_CODEX_CONFIG"

  if [[ ! -w "$TARGET_CODEX_CONFIG" ]]; then
    error_echo "目标 config.toml 不可写：${TARGET_CODEX_CONFIG}"
    exit 1
  fi

  local begin_marker="# >>> JobsCodexConfigs managed skills >>>"
  local end_marker="# <<< JobsCodexConfigs managed skills <<<"
  local temp_config=""
  temp_config="$(mktemp "/tmp/codex_config.XXXXXX.toml")"

  # 只删除本脚本上次生成的受控块，保留用户自己维护的 MCP、provider、plugin、projects 等配置。
  /usr/bin/awk -v begin="$begin_marker" -v end="$end_marker" '
    index($0, begin) { skip = 1; next }
    index($0, end) { skip = 0; next }
    skip != 1 { print }
  ' "$TARGET_CODEX_CONFIG" > "$temp_config"

  {
    cat "$temp_config"
    echo ""
    echo "$begin_marker"
    echo "# 由 JobsCodexConfigs 单向部署脚本生成。"
    echo "# 目的：让 Codex++ 管理器的 Skills 页签识别本仓库部署到用户级目录的 Skills。"
    echo "# 官方 Codex 的真实 Skill 文件仍位于：${TARGET_SKILLS_DIR}"
    local skill_name=""
    for skill_name in "${DEPLOYED_SKILL_NAMES[@]}"; do
      local skill_file="${TARGET_SKILLS_DIR}/${skill_name}/SKILL.md"
      if [[ ! -f "$skill_file" ]]; then
        warn_echo "跳过注册不存在的 Skill 文件：${skill_file}"
        continue
      fi
      echo ""
      echo "[[skills.config]]"
      echo "path = \"$(toml_escape_string "$skill_file")\""
      echo "enabled = true"
    done
    echo "$end_marker"
  } > "$TARGET_CODEX_CONFIG"

  rm -f "$temp_config"
  success_echo "已更新 Codex Skills 配置：${TARGET_CODEX_CONFIG}"
}

# 封装 open_app_target 对应的独立处理逻辑。
open_app_target() {
  # 优先按完整 .app 路径启动；路径不存在时按应用名兜底。
  local app_target="$1"
  if [[ "$app_target" == __APP_NAME__:* ]]; then
    local app_name="${app_target#__APP_NAME__:}"
    /usr/bin/open -a "$app_name"
    return $?
  fi

  /usr/bin/open "$app_target"
}

# 封装 build_codex_launcher_choice_file 对应的独立处理逻辑。
build_codex_launcher_choice_file() {
  # Codex++ 存在时，让用户通过 fzf 选择增强入口或官方入口。
  local choice_file="$1"
  : > "$choice_file"

  local codex_plus_app=""
  local codex_plus_manager_app=""
  local official_codex_app=""

  codex_plus_app="$(find_first_app_path "/Applications/Codex++.app" "${HOME}/Applications/Codex++.app")" || true
  codex_plus_manager_app="$(find_first_app_path "/Applications/Codex++ 管理工具.app" "${HOME}/Applications/Codex++ 管理工具.app")" || true
  official_codex_app="$(find_first_app_path "/Applications/Codex.app" "${HOME}/Applications/Codex.app")" || true

  if [[ -n "$codex_plus_app" ]]; then
    printf "%s\t%s\n" "Codex++｜增强启动器｜${codex_plus_app}" "${codex_plus_app}" >> "$choice_file"
  fi

  if [[ -n "$codex_plus_manager_app" ]]; then
    printf "%s\t%s\n" "Codex++ 管理工具｜检查 / 修复 / 管理增强｜${codex_plus_manager_app}" "${codex_plus_manager_app}" >> "$choice_file"
  fi

  if [[ -n "$official_codex_app" ]]; then
    printf "%s\t%s\n" "官方 Codex｜${official_codex_app}" "${official_codex_app}" >> "$choice_file"
  else
    printf "%s\t%s\n" "官方 Codex｜open -a Codex" "__APP_NAME__:Codex" >> "$choice_file"
  fi
}

# 封装 restart_codex_runtime 对应的独立处理逻辑。
restart_codex_runtime() {
  stop_codex_runtime "部署完成后准备重启 Codex。"

  local codex_plus_app=""
  local codex_plus_manager_app=""
  codex_plus_app="$(find_first_app_path "/Applications/Codex++.app" "${HOME}/Applications/Codex++.app")" || true
  codex_plus_manager_app="$(find_first_app_path "/Applications/Codex++ 管理工具.app" "${HOME}/Applications/Codex++ 管理工具.app")" || true

  if [[ -n "$codex_plus_app" || -n "$codex_plus_manager_app" ]]; then
    success_echo "已检测到 Codex++，进入 fzf 启动选择。"
    check_fzf_health || exit 1

    local choice_file=""
    local selected=""
    local launcher_target=""
    choice_file="$(mktemp "/tmp/codex_launcher.XXXXXX")"
    build_codex_launcher_choice_file "$choice_file"

    selected="$(cat "$choice_file" | fzf --height=50% --border --prompt="请选择 Codex 启动入口：" --delimiter=$'\t' --with-nth=1)"
    rm -f "$choice_file"

    if [[ -z "$selected" ]]; then
      error_echo "未选择 Codex 启动入口，已取消重启。"
      exit 1
    fi

    launcher_target="$(print -r -- "$selected" | awk -F '\t' '{print $2}')"
    if open_app_target "$launcher_target" >/dev/null 2>&1; then
      success_echo "已启动：$(print -r -- "$selected" | awk -F '\t' '{print $1}')"
    else
      warn_echo "启动失败：${launcher_target}。可手动打开 Codex 或 Codex++。"
    fi
    return 0
  fi

  info_echo "未检测到 Codex++，改为启动官方 Codex。"
  local official_codex_app=""
  official_codex_app="$(find_first_app_path "/Applications/Codex.app" "${HOME}/Applications/Codex.app")" || true
  if [[ -n "$official_codex_app" ]]; then
    if /usr/bin/open "$official_codex_app" >/dev/null 2>&1; then
      success_echo "已通过固定路径启动官方 Codex：${official_codex_app}"
    else
      warn_echo "未能通过固定路径启动官方 Codex：${official_codex_app}"
    fi
  elif /usr/bin/open -a "Codex" >/dev/null 2>&1; then
    success_echo "已通过 open -a Codex 启动官方 Codex。"
  else
    warn_echo "未能启动官方 Codex。若你使用 CLI 入口，请重新打开终端后执行 codex。"
  fi
}

# 封装 print_finish_summary 对应的独立处理逻辑。
print_finish_summary() {
  echo ""
  highlight_echo "============================== 执行完成 =============================="
  success_echo "全局 AGENTS：${TARGET_CODEX_DIR}/AGENTS.md"
  success_echo "用户级 Skills：${TARGET_SKILLS_DIR}"
  success_echo "Codex Skills 配置：${TARGET_CODEX_CONFIG}"
  if (( ${#DEPLOYED_SKILL_NAMES[@]} > 0 )); then
    success_echo "已部署 Skills：${(j:, :)DEPLOYED_SKILL_NAMES}"
  fi
  gray_echo "日志文件：${LOG_FILE}"
  highlight_echo "======================================================================="
}

# 编排完整业务流程，复杂步骤继续下沉到职责明确的函数。
run_main_flow() {
  show_readme_and_wait
  validate_toolkit_layout
  ensure_homebrew
  ensure_fzf
  ensure_codex

  stop_codex_runtime "部署前先停止 Codex，避免运行中读取旧配置。"
  deploy_global_agents
  deploy_user_skills
  update_codex_skills_config
  restart_codex_runtime
  print_finish_summary
}

# 统一收口脚本入口，仅委托已经拆分完成的业务流程。
main() {
  # 主入口只负责委托完整业务流程，复杂逻辑统一下沉。
  run_main_flow "$@"
}

main "$@"
