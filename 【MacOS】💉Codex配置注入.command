#!/bin/zsh

set -euo pipefail
setopt NO_NOMATCH

# ============================= 基础路径 =============================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
SCRIPT_PATH="${SCRIPT_DIR}/$(basename -- "$0")"
SCRIPT_BASENAME=$(basename "$0" | sed 's/\.[^.]*$//')
LOG_FILE="/tmp/${SCRIPT_BASENAME}.log"
: > "$LOG_FILE"

LOCAL_AGENTS="${SCRIPT_DIR}/AGENTS.md"
CODEX_DIR="${HOME}/.codex"
CODEX_AGENTS="${CODEX_DIR}/AGENTS.md"
RUN_MODE=""

# ============================= 彩色日志 =============================
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

# ============================= 自述 =============================
show_builtin_readme_and_choose_mode() {
  clear
  highlight_echo "============================== README =============================="
  bold_echo "Codex AGENTS.md 配置注入 / 反向同步脚本"
  echo "" | tee -a "$LOG_FILE"
  note_echo "脚本意义：把 Git 管理的 AGENTS.md 注入到当前系统 Codex 配置目录；也支持把系统正在使用的 AGENTS.md 反向同步回 Git 仓库。"
  note_echo "执行原点：脚本所在目录，而不是终端当前目录。"
  gray_echo "脚本路径：${SCRIPT_PATH}"
  gray_echo "脚本目录：${SCRIPT_DIR}"
  gray_echo "Git 管理文件：${LOCAL_AGENTS}"
  gray_echo "系统 Codex 文件：${CODEX_AGENTS}"
  gray_echo "日志文件：${LOG_FILE}"
  echo "" | tee -a "$LOG_FILE"
  warn_echo "执行模式："
  echo "  直接按 [Enter]：同步注入（${LOCAL_AGENTS} -> ${CODEX_AGENTS}）" | tee -a "$LOG_FILE"
  echo "  输入任意字符后回车：反向同步（${CODEX_AGENTS} -> ${LOCAL_AGENTS}）" | tee -a "$LOG_FILE"
  echo "" | tee -a "$LOG_FILE"
  warn_echo "覆盖目标文件前会自动生成时间戳备份。"
  highlight_echo "===================================================================="
  echo "" | tee -a "$LOG_FILE"

  local input=""
  read -r "?👉 已阅读自述文件：直接回车=同步注入；输入任意字符+回车=反向同步：" input
  [[ -n "$input" ]] && RUN_MODE="reverse" || RUN_MODE="inject"
}

pause_to_exit() {
  echo ""
  read -r "?🔚 按回车退出..." _
}

# ============================= Homebrew 自检 =============================
get_cpu_arch() {
  [[ "$(uname -m)" == "arm64" ]] && echo "arm64" || echo "x86_64"
}

resolve_brew_bin() {
  if command -v brew >/dev/null 2>&1; then
    command -v brew
  elif [[ -x "/opt/homebrew/bin/brew" ]]; then
    echo "/opt/homebrew/bin/brew"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    echo "/usr/local/bin/brew"
  else
    return 1
  fi
}

get_profile_file() {
  local shell_path="${SHELL##*/}"
  case "$shell_path" in
    zsh)  echo "$HOME/.zprofile" ;;
    bash) echo "$HOME/.bash_profile" ;;
    *)    echo "$HOME/.profile" ;;
  esac
}

inject_shellenv_block() {
  local profile_file="$1"
  local id="$2"
  local shellenv="$3"
  local header="# >>> ${id} 环境变量 >>>"
  local footer="# <<< ${id} 环境变量 <<<"

  if [[ -z "$profile_file" || -z "$id" || -z "$shellenv" ]]; then
    error_echo "缺少参数：inject_shellenv_block <profile_file> <id> <shellenv>"
    return 1
  fi

  mkdir -p "$(dirname "$profile_file")"
  touch "$profile_file"

  if grep -Fq "$header" "$profile_file" 2>/dev/null; then
    info_echo "已存在 header：$header"
  elif grep -Fq "$shellenv" "$profile_file" 2>/dev/null; then
    info_echo "已存在 shellenv：$shellenv"
  else
    {
      echo ""
      echo "$header"
      echo "$shellenv"
      echo "$footer"
    } >> "$profile_file"
    success_echo "已写入环境变量：$profile_file -> $id"
  fi

  eval "$shellenv"
  success_echo "shellenv 已在当前终端生效：$id"
}

run_brew_health_update() {
  info_echo "正在更新 Homebrew..."
  brew update  || { error_echo "brew update 失败"; return 1; }
  brew upgrade || { warn_echo  "brew upgrade 有警告/错误，请按输出处理"; }
  brew cleanup || { warn_echo  "brew cleanup 有警告/错误，请按输出处理"; }
  brew doctor  || { warn_echo  "brew doctor 有警告/错误，请按提示处理"; }
  brew -v      || { warn_echo  "打印 brew 版本失败，可忽略"; }
  success_echo "Homebrew 更新流程已完成"
}

install_homebrew_if_missing() {
  local arch="$(get_cpu_arch)"
  local brew_bin=""
  local profile_file=""
  local shellenv_cmd=""

  if brew_bin="$(resolve_brew_bin)"; then
    shellenv_cmd="eval \"\$(${brew_bin} shellenv)\""
    profile_file="$(get_profile_file)"
    inject_shellenv_block "$profile_file" "homebrew_env" "$shellenv_cmd"
    success_echo "已检测到 Homebrew：$brew_bin"
    return 0
  fi

  warn_echo "未检测到 Homebrew，准备按官方脚本安装（架构：$arch）"
  read -r "?👉 按回车开始安装 Homebrew；按 Ctrl+C 取消：" _

  if [[ "$arch" == "arm64" ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
      error_echo "Homebrew 安装失败（arm64）"
      return 1
    }
    brew_bin="/opt/homebrew/bin/brew"
  else
    arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
      error_echo "Homebrew 安装失败（x86_64）"
      return 1
    }
    brew_bin="/usr/local/bin/brew"
  fi

  [[ -x "$brew_bin" ]] || brew_bin="$(resolve_brew_bin)"
  [[ -n "$brew_bin" && -x "$brew_bin" ]] || {
    error_echo "Homebrew 安装后仍未找到 brew 可执行文件"
    return 1
  }

  profile_file="$(get_profile_file)"
  shellenv_cmd="eval \"\$(${brew_bin} shellenv)\""
  inject_shellenv_block "$profile_file" "homebrew_env" "$shellenv_cmd"
  success_echo "Homebrew 安装成功：$brew_bin"
}

self_check_homebrew() {
  install_homebrew_if_missing

  echo "" | tee -a "$LOG_FILE"
  note_echo "Homebrew 更新选项"
  gray_echo "直接按 [Enter]：跳过 brew update / upgrade"
  gray_echo "输入任意字符后回车：执行 brew update / upgrade / cleanup / doctor"

  local input=""
  IFS= read -r input
  if [[ -z "$input" ]]; then
    note_echo "已选择跳过 Homebrew 更新"
    return 0
  fi

  run_brew_health_update
}

# ============================= Codex 自检 =============================
is_codex_app_installed() {
  [[ -d "/Applications/Codex.app" || -d "${HOME}/Applications/Codex.app" ]] && return 0

  if command -v mdfind >/dev/null 2>&1; then
    mdfind 'kMDItemFSName == "Codex.app"' 2>/dev/null | grep -q '/Codex.app$' && return 0
  fi

  return 1
}

is_codex_cli_installed() {
  command -v codex >/dev/null 2>&1
}

try_install_codex_by_brew() {
  warn_echo "未检测到 Codex App / CLI，准备尝试通过 Homebrew 安装 Codex。"
  read -r "?👉 按回车开始尝试 brew 安装 Codex；按 Ctrl+C 取消：" _

  if brew info codex >/dev/null 2>&1; then
    brew install codex || return 1
    return 0
  fi

  if brew info --cask codex >/dev/null 2>&1; then
    brew install --cask codex || return 1
    return 0
  fi

  error_echo "当前 Homebrew 未找到 codex formula/cask。请先安装 Codex 后再执行本脚本。"
  return 1
}

self_check_codex() {
  local found="false"

  if is_codex_cli_installed; then
    success_echo "已检测到 Codex CLI：$(command -v codex)"
    found="true"
  fi

  if is_codex_app_installed; then
    success_echo "已检测到 Codex.app"
    found="true"
  fi

  if [[ "$found" == "true" ]]; then
    return 0
  fi

  try_install_codex_by_brew

  if is_codex_cli_installed || is_codex_app_installed; then
    success_echo "Codex 安装/检测通过"
    return 0
  fi

  error_echo "仍未检测到 Codex。该脚本依托 Codex 已安装，请先处理 Codex 安装。"
  return 1
}

# ============================= AGENTS 同步 =============================
backup_file_if_needed() {
  local target="$1"
  [[ -f "$target" ]] || return 0

  local ts backup
  ts="$(date '+%Y%m%d_%H%M%S')"
  backup="${target}.bak.${ts}"
  cp -a "$target" "$backup"
  success_echo "已备份目标文件：$backup"
}

copy_agents_file() {
  local source="$1"
  local target="$2"
  local target_dir
  target_dir="$(dirname "$target")"

  [[ -f "$source" ]] || {
    error_echo "源文件不存在：$source"
    return 1
  }

  mkdir -p "$target_dir"

  if [[ -f "$target" ]] && cmp -s "$source" "$target"; then
    success_echo "源文件与目标文件一致，无需同步：$target"
    return 0
  fi

  backup_file_if_needed "$target"
  cp -f "$source" "$target"
  success_echo "同步完成：$source -> $target"
}

sync_inject_to_system() {
  highlight_echo "开始同步注入：Git AGENTS.md -> 系统 Codex AGENTS.md"
  copy_agents_file "$LOCAL_AGENTS" "$CODEX_AGENTS"
}

sync_reverse_to_git() {
  highlight_echo "开始反向同步：系统 Codex AGENTS.md -> Git AGENTS.md"
  copy_agents_file "$CODEX_AGENTS" "$LOCAL_AGENTS"
}

# ============================= 主流程 =============================
main() {
  show_builtin_readme_and_choose_mode

  self_check_homebrew
  self_check_codex

  case "$RUN_MODE" in
    inject)  sync_inject_to_system ;;
    reverse) sync_reverse_to_git ;;
    *)       error_echo "未知执行模式：$RUN_MODE"; exit 1 ;;
  esac

  success_echo "任务完成。"
  pause_to_exit
}

main "$@"
