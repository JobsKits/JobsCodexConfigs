#!/bin/zsh
# 脚本自述：
# - 脚本名称：【MacOS】Codex配置注入替换工具.command
# - 核心用途：部署 Codex 全局 AGENTS.md，并把现行 JobsSkills 仓库注册到 Codex 配置。
# - 影响范围：可能安装或更新工具链，修改当前用户的 AGENTS.md 与 config.toml；不覆盖 JobsSkills 工作树。
# - 运行提示：运行后会先打印内置自述；终端模式按回车确认后继续，按 Ctrl+C 可取消。

# 仅渲染自述：标题红色加粗，编号正文蓝色常规字重；非彩色终端输出纯文本。
# >>> Jobs Homebrew install choice >>>
# 输出安装诊断，避免混入返回的命令路径。
jobs_brew_note() {
  print -u2 -r -- "ℹ $*"
}
# 验证候选能够执行；共享安装只读不代表未安装。
jobs_brew_candidate_ok() {
  local candidate="$1" prefix
  [[ -n "$candidate" && -x "$candidate" ]] || return 1
  HOMEBREW_NO_AUTO_UPDATE=1 "$candidate" --version >/dev/null 2>&1 || return 1
  prefix="$("$candidate" --prefix 2>/dev/null)" || return 1
  [[ "$prefix" == /* && -d "$prefix" ]]
}
# 发现既有健康安装，不以目录可写性决定是否重新安装。
jobs_brew_find() {
  local candidate
  local -a candidates
  candidates=("${JOBS_HOMEBREW_BIN:-}" "$(command -v brew 2>/dev/null)" /opt/homebrew/bin/brew /usr/local/bin/brew
    "${JOBS_HOMEBREW_INSTALL_PREFIX:-$HOME/.local/homebrew}/bin/brew" "$HOME/.homebrew/bin/brew")
  for candidate in "${candidates[@]}"; do
    if jobs_brew_candidate_ok "$candidate"; then
      print -r -- "$candidate"
      return 0
    fi
  done
  return 1
}
# 计算官方系统目录；实际支持范围和授权交由官方安装器处理。
jobs_brew_system_prefix() {
  case "$(/usr/bin/uname -m)" in
    arm64) print -r -- /opt/homebrew ;;
    *) print -r -- /usr/local ;;
  esac
}
# 缺失时强提示选择安装路径；YES 只表示选择系统目录，不验证密码或权限。
jobs_brew_choose_installation() {
  local answer="" system_prefix="$(jobs_brew_system_prefix)"
  if [[ ! -t 0 || ! -t 2 || "${IS_SOURCETREE_RUNTIME:-0}" == 1 ]]; then
    jobs_brew_note "缺少 Homebrew，需要人工选择安装路径；请在可交互终端重新运行，未执行安装。"
    return 1
  fi
  print -u2 -r -- "⚠ Homebrew 尚未就绪，必须先选择安装路径："
  print -u2 -r -- "1、输入精确大写 YES：选择系统标准目录 $system_prefix（Apple Silicon：/opt/homebrew；Intel：/usr/local）。"
  print -u2 -r -- "   这表示你准备向系统目录安装；官方安装器可能随后要求管理员密码，并自行验证权限。"
  print -u2 -r -- "2、其它输入或直接回车：选择用户目录 ${JOBS_HOMEBREW_INSTALL_PREFIX:-$HOME/.local/homebrew}，不使用 sudo；有管理员权限也可选此路径。"
  print -u2 -r -- "本步骤只选择路径，不收集或验证密码；选定路径失败就停止，不自动切换。按 Ctrl+C 取消整个任务。"
  print -u2 -n -r -- "➤ 安装路径选择："
  if ! IFS= read -r answer; then
    jobs_brew_note "输入已取消或结束，停止安装。"
    return 1
  fi
  if [[ "$answer" == YES ]]; then
    typeset -g JOBS_HOMEBREW_INSTALL_MODE=system
  else
    typeset -g JOBS_HOMEBREW_INSTALL_MODE=user
  fi
}
# 将官方系统安装器下载到临时文件后执行，失败不自动改装到用户目录。
jobs_brew_install_system() {
  local installer system_prefix="$(jobs_brew_system_prefix)" installer_result=0
  command -v curl >/dev/null 2>&1 || { jobs_brew_note "缺少 curl，无法获取官方安装器。"; return 1; }
  installer="$(mktemp "${TMPDIR:-/tmp}/jobs-homebrew-install.XXXXXX")" || return 1
  if curl -fsSL --connect-timeout 10 --max-time 120 https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$installer"; then
    /bin/bash "$installer" || installer_result=$?
  else
    installer_result=1
  fi
  rm -- "$installer"
  if (( installer_result != 0 )); then
    jobs_brew_note "系统目录安装失败（退出码 $installer_result）；停止，不自动切换安装路径。"
    return 1
  fi
  typeset -g JOBS_HOMEBREW_BIN="$system_prefix/bin/brew"
  jobs_brew_candidate_ok "$JOBS_HOMEBREW_BIN" || { jobs_brew_note "官方安装器结束后未找到健康 Homebrew：$JOBS_HOMEBREW_BIN"; return 1; }
}
# 克隆官方稳定版本到用户目录；不覆盖非空目录，不调用 sudo。
jobs_brew_install_user() {
  local prefix="${JOBS_HOMEBREW_INSTALL_PREFIX:-$HOME/.local/homebrew}" stage release_tag git_bin
  [[ "$prefix" == /* && "$prefix" != / && "$prefix" != *[[:space:]:]* ]] || {
    jobs_brew_note "Homebrew 用户前缀须为不含空白或冒号的绝对目录：$prefix"
    return 1
  }
  if [[ -L "$prefix" || ( -e "$prefix" && ! -d "$prefix" ) || ( -d "$prefix" && -n "$(ls -A "$prefix" 2>/dev/null)" ) ]]; then
    jobs_brew_note "用户安装目标非空或不是普通目录，不覆盖：$prefix"
    return 1
  fi
  git_bin="$(command -v git 2>/dev/null)"
  [[ -n "$git_bin" ]] && "$git_bin" --version >/dev/null 2>&1 || { jobs_brew_note "用户目录安装需要可用 Git；请先准备 Git / Command Line Tools。"; return 1; }
  command -v curl >/dev/null 2>&1 || { jobs_brew_note "缺少 curl，无法获取官方稳定版本。"; return 1; }
  export HOMEBREW_NO_SUDO=1
  mkdir -p "${prefix:h}" || return 1
  stage="$(mktemp -d "${prefix:h}/.jobs-homebrew.XXXXXX")" || return 1
  if ! curl -fsSL --connect-timeout 10 --max-time 60 https://api.github.com/repos/Homebrew/brew/releases/latest -o "$stage/release.json"; then
    rm -r -- "$stage"
    jobs_brew_note "获取官方稳定版本失败，停止安装。"
    return 1
  fi
  release_tag="$(sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([0-9][0-9.]*\)".*/\1/p' "$stage/release.json" | head -n 1)"
  if [[ ! "$release_tag" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]] ||
     ! GIT_TERMINAL_PROMPT=0 "$git_bin" -c http.lowSpeedLimit=1 -c http.lowSpeedTime=60 clone --depth 1 --branch "$release_tag" --single-branch https://github.com/Homebrew/brew.git "$stage/brew" ||
     ! "$git_bin" -C "$stage/brew" checkout -b stable ||
     ! "$git_bin" -C "$stage/brew" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*' ||
     ! mkdir -p "$stage/brew/Cellar" "$stage/brew/Caskroom" "$stage/brew/etc" "$stage/brew/var"; then
    rm -r -- "$stage"
    jobs_brew_note "Homebrew 用户目录初始化失败，停止安装。"
    return 1
  fi
  # 空目录也只在下载成功后移除，避免提前改动用户的目标目录。
  if [[ -d "$prefix" ]] && ! rmdir -- "$prefix"; then
    rm -r -- "$stage"
    return 1
  fi
  if ! mv "$stage/brew" "$prefix"; then
    rm -r -- "$stage"
    return 1
  fi
  rm -r -- "$stage"
  typeset -g JOBS_HOMEBREW_BIN="$prefix/bin/brew"
  jobs_brew_candidate_ok "$JOBS_HOMEBREW_BIN" || { jobs_brew_note "用户目录安装后复检失败：$prefix"; return 1; }
}
# 只更新本模块的 shellenv 配置块，并保留配置文件的符号链接和权限。
jobs_brew_save_shellenv() {
  local profile_file="$HOME/.zprofile" profile_stage shellenv_line current_shell="${SHELL:-/bin/zsh}"
  [[ "${current_shell##*/}" != bash ]] || profile_file="$HOME/.bash_profile"
  shellenv_line='eval "$('"${(q)JOBS_HOMEBREW_BIN}"' shellenv)"'
  profile_stage="$(mktemp "${TMPDIR:-/tmp}/jobs-homebrew-profile.XXXXXX")" || return 1
  if [[ -e "$profile_file" || -L "$profile_file" ]]; then
    awk '
      $0 == "# >>> Jobs Homebrew shellenv >>>" { inside = 1; block = $0 ORS; next }
      inside {
        block = block $0 ORS
        if ($0 == "# <<< Jobs Homebrew shellenv <<<") { inside = 0; block = "" }
        next
      }
      { print }
      END { if (inside) printf "%s", block }
    ' "$profile_file" > "$profile_stage" || { rm -- "$profile_stage"; return 1; }
  fi
  {
    print -r -- '# >>> Jobs Homebrew shellenv >>>'
    print -rl -- "$shellenv_line" '# <<< Jobs Homebrew shellenv <<<'
  } >> "$profile_stage"
  if ! cmp -s "$profile_stage" "$profile_file"; then
    cat "$profile_stage" > "$profile_file" || { rm -- "$profile_stage"; jobs_brew_note "无法写入用户配置：$profile_file"; return 1; }
  fi
  rm -- "$profile_stage"
}
# 激活当前进程并验证 Ruby 命令层；只有新安装才持久化 shellenv。
jobs_brew_activate() {
  local brew_env
  brew_env="$("$JOBS_HOMEBREW_BIN" shellenv)" || return 1
  eval "$brew_env" || return 1
  typeset -g JOBS_HOMEBREW_PREFIX="$("$JOBS_HOMEBREW_BIN" --prefix)"
  export PATH="$JOBS_HOMEBREW_PREFIX/bin:$JOBS_HOMEBREW_PREFIX/sbin:$PATH"
  rehash
  HOMEBREW_NO_AUTO_UPDATE=1 "$JOBS_HOMEBREW_BIN" config >/dev/null || { jobs_brew_note "Homebrew 命令层复检失败，停止后续业务。"; return 1; }
  if [[ "${1:-}" == installed ]]; then
    if [[ "${JOBS_HOMEBREW_INSTALL_MODE:-}" == user && -z "${HOMEBREW_CASK_OPTS:-}" ]]; then
      export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications"
    fi
    jobs_brew_save_shellenv || return 1
  fi
}
# 在原版安装位置复用或安装 Homebrew，安装失败必须终止外层业务。
jobs_brew_install_or_exit() {
  local installed=""
  if [[ "${DRY_RUN:-0}" == 1 ]]; then
    jobs_brew_note "演练：Homebrew 系统路径 $(jobs_brew_system_prefix)；用户路径 ${JOBS_HOMEBREW_INSTALL_PREFIX:-$HOME/.local/homebrew}；未询问或执行安装。"
    return 0
  fi
  if ! JOBS_HOMEBREW_BIN="$(jobs_brew_find)"; then
    jobs_brew_choose_installation || exit 1
    case "$JOBS_HOMEBREW_INSTALL_MODE" in
      system) jobs_brew_install_system || exit 1 ;;
      user) jobs_brew_install_user || exit 1 ;;
      *) jobs_brew_note "安装路径选择无效，停止。"; exit 1 ;;
    esac
    installed=installed
  fi
  jobs_brew_activate "$installed" || exit 1
}
# <<< Jobs Homebrew install choice <<<
jobs_intro_style() {
  local intro_color=0
  if [ -t 1 ] && [ -n "${TERM:-}" ] && [ "${TERM:-}" != dumb ] &&
     [ -z "${NO_COLOR+x}" ] && [ "${PLAIN_OUTPUT:-0}" != 1 ] &&
     [ "${IS_SOURCETREE_RUNTIME:-0}" != 1 ]; then
    intro_color=1
  fi
  /usr/bin/awk -v color="$intro_color" -v role="${1:-body}" '
    BEGIN { esc = sprintf("%c", 27) }
    {
      gsub(esc "\\[[0-9;]*m", "")
      gsub(/\\(033|e|x1[bB])\[[0-9;]*m/, "")
      if (!color || $0 ~ /^[[:space:]]*$/) { print; next }
      numbered = ($0 ~ /^[[:space:]➤ℹ🔹✔⚠]*([0-9]+[、.)）]|[0-9]+️⃣|[-•])/)
      heading = ($0 ~ /^[[:space:]]*#{1,6}[[:space:]]/ || $0 ~ /[：:][[:space:]]*$/ || $0 ~ /^[[:space:]]*[=━─-]{3}/)
      title = (!numbered && (role == "title" || heading))
      if (role == "auto" && !seen && !numbered) title = 1
      if ($0 !~ /^[[:space:]]*[=━─-]+[[:space:]]*$/) seen = 1
      printf "%s%s%s\n", esc (title ? "[1;31m" : "[0;34m"), $0, esc "[0m"
    }
  '
}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
SCRIPT_PATH="${SCRIPT_DIR}/$(basename -- "$0")"
SCRIPT_BASENAME=$(basename "$0" | sed 's/\.[^.]*$//')
LOG_FILE="/tmp/${SCRIPT_BASENAME}.log"
# 解析并返回后续流程需要的目标信息。
resolve_toolkit_dir() {
  # 脚本推荐位于：💻JobsCodexConfigs/【MacOS】Codex配置注入替换工具.command/脚本文件
  # 因此需要从脚本所在目录向上查找真正的 💻JobsCodexConfigs 根目录。
  local candidate_dir="$SCRIPT_DIR"
  local scan_depth=0

  while [[ -n "$candidate_dir" && "$candidate_dir" != "/" && "$scan_depth" -lt 8 ]]; do
    if [[ -f "${candidate_dir}/AGENTS.md" ]]; then
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
TARGET_CODEX_DIR="${TARGET_CODEX_DIR:-${HOME}/.codex}"
TARGET_CODEX_CONFIG="${TARGET_CODEX_CONFIG:-${TARGET_CODEX_DIR}/config.toml}"
TARGET_SKILLS_DIR="${TARGET_SKILLS_DIR:-${HOME}/.agents/skills}"
JOBS_SKILLS_REPOSITORY="https://github.com/JobsKits/JobsSkills.git"
BREW_BIN=""
TEMP_WORK_DIRS=()
REGISTERED_SKILL_NAMES=()
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
# 初始化 Shell 选项、日志和临时目录清理钩子。
initialize_script_runtime() {
  setopt NO_NOMATCH
  : > "$LOG_FILE"
  trap cleanup_temp_dirs EXIT INT TERM
}
# 展示脚本用途和影响范围，并在执行前等待用户确认。
show_script_intro_and_wait() {

  clear
  print -r -- '============================== 脚本内置自述 ==============================' | jobs_intro_style title
  print -r -- '脚本名称：【MacOS】Codex配置注入替换工具.command' | jobs_intro_style title
  print -r -- '核心用途：部署 Codex 全局 AGENTS.md，并把现行 JobsSkills 仓库注册到 Codex 配置。' | jobs_intro_style body
  print -r -- '影响范围：可能安装或更新工具链，修改当前用户的 AGENTS.md 与 config.toml；不覆盖 JobsSkills 工作树。' | jobs_intro_style body
  print -r -- '取消方式：确认前按 Ctrl+C 终止，不会继续执行后续业务。' | jobs_intro_style body
  print -r -- '============================================================================' | jobs_intro_style title
  echo "" | jobs_intro_style body
  read -r "?👉 已了解脚本用途与影响，按回车继续；按 Ctrl+C 取消：" _
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
  jobs_brew_find
}
# 检查当前运行条件是否满足后续流程要求。
ensure_homebrew_shellenv() {
  local jobs_existing_brew=""
  if jobs_existing_brew="$(jobs_brew_find)"; then
    JOBS_HOMEBREW_BIN="$jobs_existing_brew"
    jobs_brew_activate || return 1
  fi
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
  if [[ "${DRY_RUN:-0}" == 1 ]]; then
    jobs_brew_install_or_exit
    return 0
  fi
  warn_echo "未检测到 Homebrew。"
  if ! ask_any_to_run "是否安装 Homebrew"; then
    error_echo "缺少 Homebrew，无法继续安装 fzf / Codex。"
    exit 1
  fi

  jobs_brew_install_or_exit

}
# 检查当前运行条件是否满足后续流程要求。
ensure_homebrew() {
  local jobs_existing_brew=""
  if jobs_existing_brew="$(jobs_brew_find)"; then
    JOBS_HOMEBREW_BIN="$jobs_existing_brew"
    jobs_brew_activate || exit 1
  fi
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
  ensure_homebrew_shellenv "$BREW_BIN" || exit 1
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

  if [[ ! -d "$TARGET_SKILLS_DIR" ]]; then
    error_echo "未找到 JobsSkills 工作树：${TARGET_SKILLS_DIR}"
    exit 1
  fi

  if ! command -v git >/dev/null 2>&1; then
    error_echo "缺少 Git，无法核验 JobsSkills 工作树。请先安装 Xcode Command Line Tools 或 Git。"
    exit 1
  fi

  if ! git -C "$TARGET_SKILLS_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    error_echo "JobsSkills 路径不是 Git 仓库：${TARGET_SKILLS_DIR}"
    exit 1
  fi

  local skills_remote=""
  skills_remote="$(git -C "$TARGET_SKILLS_DIR" remote get-url origin 2>/dev/null || true)"
  case "$skills_remote" in
    "https://github.com/JobsKits/JobsSkills"|"$JOBS_SKILLS_REPOSITORY"|"git@github.com:JobsKits/JobsSkills.git"|"ssh://git@github.com/JobsKits/JobsSkills.git")
      ;;
    *)
      error_echo "JobsSkills origin 不匹配：${skills_remote:-<缺失>}"
      exit 1
      ;;
  esac

  local first_skill=""
  first_skill="$(find -L "$TARGET_SKILLS_DIR" -mindepth 2 -maxdepth 2 -name 'SKILL.md' -type f -print -quit 2>/dev/null)"
  if [[ -z "$first_skill" ]]; then
    error_echo "JobsSkills 中没有发现任何 SKILL.md：${TARGET_SKILLS_DIR}"
    exit 1
  fi

  success_echo "工具包目录检查通过。"
  gray_echo "工具包根目录：${TOOLKIT_DIR}"
  gray_echo "全局 AGENTS 源：${GLOBAL_AGENTS_PATH}"
  gray_echo "JobsSkills 工作树：${TARGET_SKILLS_DIR}"
  gray_echo "JobsSkills 标准远端：${JOBS_SKILLS_REPOSITORY}"
  gray_echo "JobsSkills origin：${skills_remote}"
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
# 从现行 JobsSkills 工作树收集可注册的 Skill，不复制或删除仓库内容。
collect_user_skills() {
  REGISTERED_SKILL_NAMES=()
  local skill_file=""
  local skill_name=""
  while IFS= read -r -d '' skill_file; do
    skill_name="${skill_file:h:t}"
    REGISTERED_SKILL_NAMES+=("$skill_name")
  done < <(find -L "$TARGET_SKILLS_DIR" -mindepth 2 -maxdepth 2 -name 'SKILL.md' -type f -print0)

  if (( ${#REGISTERED_SKILL_NAMES[@]} == 0 )); then
    error_echo "JobsSkills 中没有可注册的 Skill：${TARGET_SKILLS_DIR}"
    exit 1
  fi

  success_echo "JobsSkills 扫描完成，共发现 ${#REGISTERED_SKILL_NAMES[@]} 个 Skill；未覆盖工作树。"
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
  if (( ${#REGISTERED_SKILL_NAMES[@]} == 0 )); then
    warn_echo "没有已发现的 Skill，跳过 config.toml Skills 注册。"
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
    echo "# 由 JobsCodexConfigs 配置注入脚本生成。"
    echo "# 目的：让 Codex++ 管理器的 Skills 页签识别 JobsSkills 用户级仓库。"
    echo "# 官方 Codex 的真实 Skill 文件仍位于：${TARGET_SKILLS_DIR}"
    local skill_name=""
    for skill_name in "${REGISTERED_SKILL_NAMES[@]}"; do
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
  if (( ${#REGISTERED_SKILL_NAMES[@]} > 0 )); then
    success_echo "已注册 Skills：${(j:, :)REGISTERED_SKILL_NAMES}"
  fi
  gray_echo "日志文件：${LOG_FILE}"
  highlight_echo "======================================================================="
}
# 编排脚本的高层业务流程。
main() {
  # 展示脚本内置自述，并按运行入口完成防误触确认。
  show_script_intro_and_wait
  # 初始化 Shell 选项、日志和退出清理钩子。
  initialize_script_runtime
  # 检查当前环境与执行条件是否满足脚本要求。
  validate_toolkit_layout
  # 检查当前环境与执行条件是否满足脚本要求。
  ensure_homebrew
  # 检查当前环境与执行条件是否满足脚本要求。
  ensure_fzf
  # 检查当前环境与执行条件是否满足脚本要求。
  ensure_codex
  # 执行 stop_codex_runtime 对应的核心业务步骤。
  stop_codex_runtime "部署前先停止 Codex，避免运行中读取旧配置。"
  # 执行 deploy_global_agents 对应的核心业务步骤。
  deploy_global_agents
  # 扫描现行 JobsSkills 工作树，只收集注册项而不覆盖仓库。
  collect_user_skills
  # 执行 update_codex_skills_config 对应的核心业务步骤。
  update_codex_skills_config
  # 执行 restart_codex_runtime 对应的核心业务步骤。
  restart_codex_runtime
  # 输出脚本执行结果、摘要和日志位置。
  print_finish_summary
}

main "$@"
