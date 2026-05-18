#!/bin/zsh
setopt NO_NOMATCH

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
SCRIPT_PATH="${SCRIPT_DIR}/$(basename -- "$0")"
SCRIPT_BASENAME=$(basename "$0" | sed 's/\.[^.]*$//')
LOG_FILE="/tmp/${SCRIPT_BASENAME}.log"
: > "$LOG_FILE"

resolve_toolkit_dir() {
  if [[ -d "${SCRIPT_DIR}/codex配置文件夹" || -f "${SCRIPT_DIR}/AGENTS.md" ]]; then
    print -r -- "$SCRIPT_DIR"
    return 0
  fi

  if [[ -d "${SCRIPT_DIR}/../codex配置文件夹" || -f "${SCRIPT_DIR}/../AGENTS.md" ]]; then
    cd "${SCRIPT_DIR}/.." && pwd
    return 0
  fi

  print -r -- "$SCRIPT_DIR"
}

TOOLKIT_DIR="$(resolve_toolkit_dir)"
CONFIGS_DIR="${TOOLKIT_DIR}/codex配置文件夹"
GLOBAL_AGENTS_PATH="${TOOLKIT_DIR}/AGENTS.md"
TARGET_CODEX_DIR="${TARGET_CODEX_DIR:-${HOME}/.codex}"
BREW_BIN=""
SOURCE_CODEX_DIR=""

log()            { echo -e "$1" | tee -a "$LOG_FILE"; }
color_echo()     { log "\033[1;32m$1\033[0m"; }
info_echo()      { log "\033[1;34mℹ $1\033[0m"; }
success_echo()   { log "\033[1;32m✔ $1\033[0m"; }
warn_echo()      { log "\033[1;33m⚠ $1\033[0m"; }
warm_echo()      { log "\033[1;33m$1\033[0m"; }
note_echo()      { log "\033[1;35m➤ $1\033[0m"; }
error_echo()     { log "\033[1;31m✖ $1\033[0m"; }
err_echo()       { log "\033[1;31m$1\033[0m"; }
debug_echo()     { log "\033[1;35m🐞 $1\033[0m"; }
highlight_echo() { log "\033[1;36m🔹 $1\033[0m"; }
gray_echo()      { log "\033[0;90m$1\033[0m"; }
bold_echo()      { log "\033[1m$1\033[0m"; }
underline_echo() { log "\033[4m$1\033[0m"; }

run_command() {
  info_echo "执行：$*"
  "$@" 2>&1 | tee -a "$LOG_FILE"
  local status=${pipestatus[1]}
  if [[ "$status" -ne 0 ]]; then
    error_echo "命令执行失败，退出码：${status}"
  fi
  return "$status"
}

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

ask_any_to_run() {
  local message="$1"
  local answer=""
  read -r "?${message}（直接回车跳过；输入任意字符后回车执行）：" answer
  [[ -n "$answer" ]]
}

confirm_yes() {
  echo ""
  warn_echo "⚠ $1"
  gray_echo "危险操作必须输入 YES 后回车；其它输入一律取消。"
  local input=""
  IFS= read -r "input?➤ "
  [[ "$input" == "YES" ]]
}

strip_outer_quotes() {
  local value="$1"
  value="${value%$'\r'}"
  value="${value%$'\n'}"
  value="${value#"}"
  value="${value%"}"
  value="${value#\'}"
  value="${value%\'}"
  print -r -- "$value"
}

get_cpu_arch() {
  [[ "$(uname -m)" == "arm64" ]] && echo "arm64" || echo "x86_64"
}

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
      echo "eval "\$(${brew_path} shellenv)""
      echo "$footer"
    } >> "$zprofile_path"
    success_echo "已写入 Homebrew shellenv 到：${zprofile_path}"
  else
    gray_echo "已存在 Homebrew shellenv 配置块，跳过重复写入。"
  fi
}

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

ensure_fzf() {
  if command -v fzf >/dev/null 2>&1; then
    success_echo "已检测到 fzf：$(command -v fzf)"
    return 0
  fi

  warn_echo "未检测到 fzf，脚本需要 fzf 菜单选择配置。"
  if ! ask_any_to_run "是否执行 brew install fzf"; then
    error_echo "缺少 fzf，无法继续选择 .codex 配置。"
    exit 1
  fi

  run_command "$BREW_BIN" install fzf || exit 1
  if ! command -v fzf >/dev/null 2>&1; then
    error_echo "fzf 安装后仍不可用，请重新打开终端或检查 Homebrew PATH。"
    exit 1
  fi
  success_echo "fzf 安装完成：$(command -v fzf)"
}

is_cask_installed() {
  local cask_name="$1"
  "$BREW_BIN" list --cask "$cask_name" >/dev/null 2>&1
}

ensure_codex() {
  local required_casks=(codex-app codex)
  local missing_casks=()

  for cask_name in "${required_casks[@]}"; do
    if is_cask_installed "$cask_name"; then
      success_echo "已检测到 Codex Cask：${cask_name}"
    else
      missing_casks+=("$cask_name")
      warn_echo "未检测到 Codex Cask：${cask_name}"
    fi
  done

  if (( ${#missing_casks[@]} > 0 )); then
    local missing_text="${(j: :)missing_casks}"
    if ! ask_any_to_run "是否安装缺失的 Codex Cask：${missing_text}"; then
      error_echo "缺少 Codex，替换配置没有意义，已终止。"
      exit 1
    fi

    for cask_name in "${missing_casks[@]}"; do
      run_command "$BREW_BIN" install --cask "$cask_name" || exit 1
    done
  else
    if ask_any_to_run "是否执行 Codex 自检与升级：brew update && brew upgrade --cask codex-app codex && brew cleanup && brew doctor && brew info --cask codex-app codex"; then
      run_command "$BREW_BIN" update || exit 1
      run_command "$BREW_BIN" upgrade --cask codex-app || true
      run_command "$BREW_BIN" upgrade --cask codex || true
      run_command "$BREW_BIN" cleanup || exit 1
      run_command "$BREW_BIN" doctor || true
      run_command "$BREW_BIN" info --cask codex-app codex || true
    else
      gray_echo "已跳过 Codex 升级 / 自检。"
    fi
  fi

  if [[ -d "/Applications/Codex.app" || -d "${HOME}/Applications/Codex.app" ]]; then
    success_echo "已检测到 Codex App。"
  else
    warn_echo "未在 /Applications 或 ~/Applications 检测到 Codex.app；如果 cask 安装路径不同，可忽略此提示。"
  fi

  if command -v codex >/dev/null 2>&1; then
    success_echo "已检测到 Codex CLI：$(command -v codex)"
  else
    warn_echo "未检测到 codex CLI；如果你只使用 Codex App，可忽略此提示。"
  fi
}

validate_toolkit_layout() {
  if [[ ! -d "$CONFIGS_DIR" ]]; then
    error_echo "未找到配置目录：${CONFIGS_DIR}"
    exit 1
  fi

  if [[ ! -f "$GLOBAL_AGENTS_PATH" ]]; then
    error_echo "未找到全局 AGENTS.md：${GLOBAL_AGENTS_PATH}"
    exit 1
  fi

  success_echo "工具包目录检查通过。"
  gray_echo "工具包根目录：${TOOLKIT_DIR}"
  gray_echo "配置目录：${CONFIGS_DIR}"
  gray_echo "全局 AGENTS：${GLOBAL_AGENTS_PATH}"
  gray_echo "目标注入目录：${TARGET_CODEX_DIR}"
}

source_codex_has_effective_content() {
  local source_dir="$1"
  local first_item=""
  first_item="$(find "$source_dir" -mindepth 1 \
    ! -name ".DS_Store" \
    ! -name ".localized" \
    -print -quit 2>/dev/null)"
  [[ -n "$first_item" ]]
}

wait_until_source_codex_ready() {
  local source_dir="$1"
  local parent_dir="$(dirname "$source_dir")"
  local account_name="$(basename "$parent_dir")"

  while true; do
    if [[ ! -d "$source_dir" ]]; then
      error_echo "选中的 .codex 目录不存在：${source_dir}"
      warn_echo "请按 codex配置文件夹/${account_name}/.codex 修正目录结构。"
      /usr/bin/open "$parent_dir" >/dev/null 2>&1 || /usr/bin/open "$CONFIGS_DIR" >/dev/null 2>&1 || true
    elif source_codex_has_effective_content "$source_dir"; then
      success_echo "来源 .codex 自检通过：${source_dir}"
      return 0
    else
      warn_echo "来源 .codex 是空目录，禁止注入：${source_dir}"
      warm_echo "请先把真实 Codex 配置放进这个 .codex，再回到终端按回车复检。"
      /usr/bin/open "$source_dir" >/dev/null 2>&1 || true
    fi

    echo ""
    local answer=""
    read -r "?👉 修正完成后按回车重新自检；按 Ctrl+C 取消：" answer
  done
}

build_source_choice_file() {
  local choice_file="$1"
  : > "$choice_file"

  find "$CONFIGS_DIR" -mindepth 2 -maxdepth 2 -type d -name ".codex" -print0 | while IFS= read -r -d '' codex_dir; do
    local parent_name="$(basename "$(dirname "$codex_dir")")"
    print -r -- "${parent_name}\t${codex_dir}" >> "$choice_file"
  done
}

select_source_codex_dir() {
  local choice_file=""
  choice_file="$(mktemp "/tmp/codex_choices.XXXXXX")"

  while true; do
    build_source_choice_file "$choice_file"

    if [[ ! -s "$choice_file" ]]; then
      warn_echo "没有发现可注入的 .codex 目录。请按：codex配置文件夹/账户名/.codex 放置配置。"
      /usr/bin/open "$CONFIGS_DIR" >/dev/null 2>&1 || true
      local answer=""
      read -r "?👉 修正目录结构后按回车重新扫描；按 Ctrl+C 取消：" answer
      continue
    fi

    local selected=""
    selected="$(cat "$choice_file" | fzf --height=60% --border --prompt="请选择要注入的 .codex 配置：" --delimiter=$'\t' --with-nth=1)"

    if [[ -z "$selected" ]]; then
      rm -f "$choice_file"
      error_echo "未选择任何 .codex 配置，已取消。"
      exit 1
    fi

    local source_dir="$(print -r -- "$selected" | awk -F '\t' '{print $2}')"
    wait_until_source_codex_ready "$source_dir"
    rm -f "$choice_file"
    SOURCE_CODEX_DIR="$source_dir"
    return 0
  done
}

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

open_target_for_manual_handling() {
  warn_echo "即将打开已有目标目录，请手动删除 / 迁移 / 备份：${TARGET_CODEX_DIR}"
  /usr/bin/open "$TARGET_CODEX_DIR" >/dev/null 2>&1 || true
  local answer=""
  read -r "?手动处理完成后按回车继续检测；按 Ctrl+C 取消：" answer
}

backup_existing_codex() {
  local timestamp="$(date '+%Y.%m.%d %H：%M：%S')"
  local backup_zip="${HOME}/.codex@${timestamp}.zip"

  if [[ -e "$backup_zip" ]]; then
    backup_zip="${HOME}/.codex@${timestamp}.${RANDOM}.zip"
  fi

  info_echo "开始压缩备份：${TARGET_CODEX_DIR}"
  info_echo "备份文件：${backup_zip}"
  if ! run_command /usr/bin/ditto -c -k --sequesterRsrc --keepParent "$TARGET_CODEX_DIR" "$backup_zip"; then
    error_echo "压缩备份失败，原目录保持不动。"
    return 1
  fi

  success_echo "压缩备份完成：${backup_zip}"
  if ! confirm_yes "备份已完成。现在必须删除原 ${TARGET_CODEX_DIR}，才能创建干净注入环境。"; then
    warn_echo "你没有确认删除原目录，脚本将回到处理菜单。"
    return 1
  fi

  run_command /bin/rm -rf -- "$TARGET_CODEX_DIR" || return 1
  if [[ -e "$TARGET_CODEX_DIR" ]]; then
    error_echo "删除后目标目录仍存在：${TARGET_CODEX_DIR}"
    return 1
  fi

  success_echo "原 .codex 已清理，注入环境已干净。"
  return 0
}

prepare_clean_target() {
  while [[ -e "$TARGET_CODEX_DIR" ]]; do
    if [[ ! -d "$TARGET_CODEX_DIR" ]]; then
      error_echo "目标路径已存在但不是目录：${TARGET_CODEX_DIR}"
      error_echo "请手动处理该路径后重新执行脚本。"
      exit 1
    fi

    local action=""
    action="$(printf "%s\n" "手动处理" "压缩备份处理" "取消执行" | fzf --height=40% --border --prompt="目标 .codex 已存在，请选择处理方式：")"

    case "$action" in
      "手动处理")
        open_target_for_manual_handling
        ;;
      "压缩备份处理")
        backup_existing_codex || true
        ;;
      "取消执行"|"")
        error_echo "已取消执行。"
        exit 1
        ;;
      *)
        warn_echo "未知选项：${action}"
        ;;
    esac
  done

  success_echo "目标目录不存在，已满足干净注入条件：${TARGET_CODEX_DIR}"
}

inject_codex_config() {
  local source_codex_dir="$1"

  if [[ -e "$TARGET_CODEX_DIR" ]]; then
    error_echo "目标目录仍存在，禁止注入：${TARGET_CODEX_DIR}"
    exit 1
  fi

  stop_codex_runtime "替换前先停止 Codex，避免运行中写入配置。"

  info_echo "开始注入 .codex 配置。"
  gray_echo "来源：${source_codex_dir}"
  gray_echo "目标：${TARGET_CODEX_DIR}"

  if ! run_command /usr/bin/ditto "$source_codex_dir" "$TARGET_CODEX_DIR"; then
    error_echo "注入 .codex 失败。"
    exit 1
  fi

  if [[ ! -d "$TARGET_CODEX_DIR" ]]; then
    error_echo "注入后目标目录不存在：${TARGET_CODEX_DIR}"
    exit 1
  fi

  info_echo "覆盖写入全局唯一 AGENTS.md。"
  if ! run_command /bin/cp -f "$GLOBAL_AGENTS_PATH" "${TARGET_CODEX_DIR}/AGENTS.md"; then
    error_echo "覆盖 AGENTS.md 失败。"
    exit 1
  fi

  success_echo ".codex 注入完成，AGENTS.md 已覆盖。"
}

restart_codex_runtime() {
  stop_codex_runtime "替换完成后强制重启 Codex。"

  if /usr/bin/open -a "Codex" >/dev/null 2>&1; then
    success_echo "已通过 open -a Codex 重新启动 Codex。"
  else
    warn_echo "未能通过 open -a Codex 启动 Codex。若你使用 CLI 入口，请重新打开终端后执行 codex。"
  fi
}

print_finish_summary() {
  echo ""
  highlight_echo "============================== 执行完成 =============================="
  success_echo "目标 .codex：${TARGET_CODEX_DIR}"
  success_echo "全局 AGENTS：${TARGET_CODEX_DIR}/AGENTS.md"
  gray_echo "日志文件：${LOG_FILE}"
  highlight_echo "======================================================================="
}

main() {
  show_readme_and_wait
  validate_toolkit_layout
  ensure_homebrew
  ensure_fzf
  ensure_codex

  select_source_codex_dir
  note_echo "已选择配置：${SOURCE_CODEX_DIR}"

  prepare_clean_target
  inject_codex_config "$SOURCE_CODEX_DIR"
  restart_codex_runtime
  print_finish_summary
}

main "$@"
