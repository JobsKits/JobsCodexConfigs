#!/bin/zsh
# 脚本自述：
# - 脚本名称：【MacOS】同步Codex配置到WorkBuddy.command
# - 核心用途：把本仓库的全局工作规约与用户级 Skills 单向同步到 WorkBuddy。
# - 影响范围：写入 ~/.workbuddy/skills/<skill>/ 与个人 MEMORY.md 受管块；不改 config.toml、不改 ~/.codex、不改本仓库。
# - 运行提示：运行后先打印内置自述并等待回车；预览变更后输入 YES 才执行，Ctrl+C 可取消。

typeset -g SCRIPT_DIR SCRIPT_PATH SCRIPT_BASENAME LOG_FILE
typeset -g WORKBUDDY_HOME SKILLS_TARGET PERSONAL_DIR MEMORY_FILE
typeset -g REPO_SKILLS_DIR GLOBAL_SOURCE GLOBAL_SKILL_NAME STAGING_ROOT STAGING_SKILLS
typeset -g BACKUP_ROOT BACKUP_DIR HOME_OLD DOCS_HOST_DIR REPO_COMMIT
typeset -g START_MARKER END_MARKER RENDERED_GLOBAL MEMORY_BLOCK GLOBAL_SKILL_FILE
typeset -g BEGIN_MARK_QUERY END_MARK_QUERY
typeset -g DRY_RUN=0 ASSUME_YES=0 SKILLS_ONLY=0 GLOBAL_ONLY=0 FORCE_SKILLS=0
typeset -g VERIFY_FAILED=0
typeset -ga SKILL_NAMES SYNCED_SKILLS SKIPPED_SKILLS REWRITE_TARGETS

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
SCRIPT_PATH="${SCRIPT_DIR}/$(basename -- "$0")"
SCRIPT_BASENAME=$(basename "$0" | sed 's/\.[^.]*$//')

# 统一日志出口；未初始化日志文件时只打印到终端，避免早期报错静默。
log()            { if [[ -n "${LOG_FILE:-}" ]]; then echo -e "$1" | tee -a "$LOG_FILE"; else echo -e "$1"; fi }
color_echo()     { log "\033[1;32m$1\033[0m"; }
info_echo()      { log "\033[1;34mℹ $1\033[0m"; }
success_echo()   { log "\033[1;32m✔ $1\033[0m"; }
warn_echo()      { log "\033[1;33m⚠ $1\033[0m"; }
note_echo()      { log "\033[1;35m➤ $1\033[0m"; }
error_echo()     { log "\033[1;31m✖ $1\033[0m"; }
highlight_echo() { log "\033[1;36m🔹 $1\033[0m"; }
gray_echo()      { log "\033[0;90m$1\033[0m"; }
bold_echo()      { log "\033[1m$1\033[0m"; }
# 打印脚本内置自述；帮助模式不写日志、不创建目录。
show_help() {
  print -r -- '【MacOS】同步Codex配置到WorkBuddy.command'
  print -r -- '  用法：./【MacOS】同步Codex配置到WorkBuddy.command [--dry-run] [--yes] [--skills-only] [--global-only] [--force-skills] [--help]'
  print -r -- '  作用：把本仓库 workbuddy/AGENTS.workbuddy.md 渲染成 WorkBuddy 常驻记忆块与全局技能，'
  print -r -- '        并把 skills/ 下的用户级 Skill 包部署到 ~/.workbuddy/skills/。'
  print -r -- '  改写：/Users/jobs → 当前 HOME；Documents/Github → 本机实际文档仓库目录；'
  print -r -- '        仅在 Codex 指代执行主体的短语处改写为 WorkBuddy，JobsCodexConfigs / JobsCodexMemory 等专有名词保持原样。'
  print -r -- '  保护：只覆盖带 .jobs-workbuddy-managed.json 标记的技能目录；覆盖前完整备份。'
  print -r -- '  --dry-run       只预览，不备份、不写入。'
  print -r -- '  --yes           跳过自述确认与 YES 确认，供自动化调用。'
  print -r -- '  --skills-only   只同步 Skills，不动全局记忆块。'
  print -r -- '  --global-only   只同步全局记忆块与全局技能，不动其它 Skills。'
  print -r -- '  --force-skills  允许覆盖没有托管标记的同名技能目录（会先备份）。'
}
# 解析入口参数；--help 直接退出，不做任何写入。
parse_args() {
  local arg
  for arg in "$@"; do
    case "$arg" in
      --help|-h) show_help; exit 0 ;;
      --dry-run) DRY_RUN=1 ;;
      --yes|-y) ASSUME_YES=1 ;;
      --skills-only) SKILLS_ONLY=1 ;;
      --global-only) GLOBAL_ONLY=1 ;;
      --force-skills) FORCE_SKILLS=1 ;;
      *) error_echo "未知参数：${arg}"; show_help; exit 2 ;;
    esac
  done
  if (( SKILLS_ONLY && GLOBAL_ONLY )); then
    error_echo "--skills-only 与 --global-only 不能同时使用。"
    exit 2
  fi
}
# 初始化日志、路径变量与中断恢复提示；不做任何业务写入。
init_runtime() {
  setopt NO_NOMATCH
  local tmp_base="${TMPDIR:-/tmp}"
  tmp_base="${tmp_base%/}"
  LOG_FILE="${tmp_base}/${SCRIPT_BASENAME}.log"
  : > "$LOG_FILE"
  trap 'error_echo "已中断；已写入的技能可用 $BACKUP_DIR 恢复。"; exit 130' INT
  WORKBUDDY_HOME="${HOME}/.workbuddy"
  SKILLS_TARGET="${WORKBUDDY_HOME}/skills"
  REPO_SKILLS_DIR="${SCRIPT_DIR}/skills"
  GLOBAL_SOURCE="${SCRIPT_DIR}/workbuddy/AGENTS.workbuddy.md"
  GLOBAL_SKILL_NAME="jobs-workbuddy-global"
  STAGING_ROOT="${tmp_base}/${SCRIPT_BASENAME}.staging.$$"
  STAGING_SKILLS="${STAGING_ROOT}/skills"
  BACKUP_ROOT="${XDG_STATE_HOME:-${HOME}/.local/state}/jobs-workbuddy-sync/backups"
  HOME_OLD="/Users/jobs"
  START_MARKER='<!-- JOBS-WORKBUDDY-GLOBAL:START 由 💻JobsCodexConfigs 同步脚本生成，请勿手改 -->'
  END_MARKER='<!-- JOBS-WORKBUDDY-GLOBAL:END -->'
  BEGIN_MARK_QUERY="JOBS-WORKBUDDY-GLOBAL:START"
  END_MARK_QUERY="JOBS-WORKBUDDY-GLOBAL:END"
  RENDERED_GLOBAL="${STAGING_ROOT}/AGENTS.workbuddy.rendered.md"
  MEMORY_BLOCK="${STAGING_ROOT}/memory.block.md"
  GLOBAL_SKILL_FILE="${STAGING_ROOT}/${GLOBAL_SKILL_NAME}/SKILL.md"
  REPO_COMMIT="$(git -C "$SCRIPT_DIR" rev-parse --short HEAD 2>/dev/null || print -r -- unknown)"
  DOCS_HOST_DIR="$(resolve_docs_host_dir)"
}
# 兼容两套文档仓库根目录：优先本机实际存在的 Gitee 目录，否则回落 Github。
resolve_docs_host_dir() {
  if [[ -d "${HOME}/Documents/Gitee" ]]; then
    print -r -- "Gitee"
  elif [[ -d "${HOME}/Documents/Github" ]]; then
    print -r -- "Github"
  else
    print -r -- "Github"
  fi
}
# 打印内置自述并等待回车；非交互环境要求显式 --yes，避免静默执行。
show_script_intro_and_wait() {
  local answer=""
  clear 2>/dev/null || true
  highlight_echo "====================== 脚本自述 ======================"
  note_echo "当前脚本：${SCRIPT_PATH}"
  note_echo "核心用途：把本仓库的全局工作规约与用户级 Skills 单向同步到 WorkBuddy。"
  warn_echo "影响范围：写入 ${SKILLS_TARGET} 与个人 MEMORY.md 受管块。"
  warn_echo "不改对象：config.toml（Codex 专有）、~/.codex、本仓库文件。"
  gray_echo "覆盖保护：只覆盖带托管标记的技能目录；覆盖前完整备份，可随时恢复。"
  gray_echo "日志位置：${LOG_FILE}"
  gray_echo "取消方式：按 Ctrl+C 终止，不会继续执行后续业务。"
  if (( DRY_RUN )); then
    note_echo "当前模式：--dry-run，只预览不做任何写入。"
  fi
  highlight_echo "======================================================"
  if (( ASSUME_YES )); then
    note_echo "已指定 --yes，跳过回车确认。"
    return 0
  fi
  if [[ ! -t 0 ]]; then
    error_echo "当前没有可交互标准输入，不能确认；请在终端重新运行，或显式加 --yes。"
    return 1
  fi
  echo ""
  read -r "?👉 已了解脚本用途与影响，按回车继续；按 Ctrl+C 取消：" answer
}
# 校验源文件、目标目录与依赖命令，并给出配置漂移提醒。
check_environment() {
  local command_name missing=0
  info_echo "开始检查同步前提。"
  [[ -f "${SCRIPT_DIR}/AGENTS.md" ]] || { error_echo "缺少全局规范源：${SCRIPT_DIR}/AGENTS.md"; missing=1; }
  [[ -f "$GLOBAL_SOURCE" ]] || { error_echo "缺少 WorkBuddy 镜像源：${GLOBAL_SOURCE}"; missing=1; }
  [[ -d "$REPO_SKILLS_DIR" ]] || { error_echo "缺少 skills 目录：${REPO_SKILLS_DIR}"; missing=1; }
  for command_name in rsync perl awk git; do
    command -v "$command_name" >/dev/null 2>&1 || { error_echo "缺少命令：${command_name}"; missing=1; }
  done
  [[ -d "$WORKBUDDY_HOME" ]] || { error_echo "未发现 WorkBuddy 配置目录：${WORKBUDDY_HOME}；请先启动一次 WorkBuddy。"; missing=1; }
  (( missing )) && { error_echo "前置检查未通过，已停止。"; return 1; }
  collect_skill_names || return 1
  resolve_personal_dir || return 1
  if [[ "${SCRIPT_DIR}/AGENTS.md" -nt "$GLOBAL_SOURCE" ]]; then
    warn_echo "AGENTS.md 比 workbuddy/AGENTS.workbuddy.md 新：全局规范可能已变更，请先更新镜像再同步。"
  fi
  success_echo "前置检查通过：${#SKILL_NAMES} 个技能待同步；目标记忆文件 ${MEMORY_FILE}"
}
# 收集根层带 SKILL.md 的技能包名；不含脚本、README 与嵌套子技能。
collect_skill_names() {
  local dir
  SKILL_NAMES=()
  for dir in "${REPO_SKILLS_DIR}"/*(/); do
    [[ -f "${dir}/SKILL.md" ]] && SKILL_NAMES+=("$(basename "$dir")")
  done
  if (( ${#SKILL_NAMES} == 0 )); then
    error_echo "skills 子模块为空：请先拉取子模块再同步。"
    return 1
  fi
}
# 定位个人配置目录；多个候选时选最近更新的 MEMORY.md 所在目录。
resolve_personal_dir() {
  local candidate chosen="" chosen_mtime=0 mtime
  local -a candidates
  candidates=("${WORKBUDDY_HOME}"/user-*-personal(N/))
  if (( ${#candidates} == 0 )); then
    error_echo "未发现个人配置目录 ${WORKBUDDY_HOME}/user-*-personal；请先启动一次 WorkBuddy 生成。"
    return 1
  fi
  for candidate in "${candidates[@]}"; do
    [[ -f "${candidate}/MEMORY.md" ]] || continue
    mtime=$(stat -f '%m' "${candidate}/MEMORY.md" 2>/dev/null || print -r -- 0)
    if (( mtime >= chosen_mtime )); then
      chosen="$candidate"
      chosen_mtime=$mtime
    fi
  done
  if [[ -z "$chosen" ]]; then
    chosen="${candidates[1]}"
  fi
  PERSONAL_DIR="$chosen"
  MEMORY_FILE="${PERSONAL_DIR}/MEMORY.md"
  if [[ "$MEMORY_FILE" != "${HOME}/"* ]]; then
    error_echo "记忆文件路径异常，拒绝写入：${MEMORY_FILE}"
    return 1
  fi
}
# 清理上一轮临时区；只在确认路径位于系统临时目录且带固定前缀时删除。
reset_staging_root() {
  case "$STAGING_ROOT" in
    "${TMPDIR:-/tmp}/${SCRIPT_BASENAME}.staging."*) command rm -rf -- "$STAGING_ROOT" ;;
    *) error_echo "临时目录路径异常，拒绝清理：${STAGING_ROOT}"; return 1 ;;
  esac
}
# 复制技能包到临时区，并排除 Git 元数据、目录脚本与仓库级配置。
prepare_staging() {
  info_echo "复制技能包到临时区。"
  reset_staging_root
  /bin/mkdir -p "$STAGING_SKILLS" || { error_echo "创建临时目录失败：${STAGING_SKILLS}"; return 1; }
  local name
  REWRITE_TARGETS=()
  for name in "${SKILL_NAMES[@]}"; do
    /usr/bin/rsync -a \
      --exclude '.git' --exclude '.gitattributes' --exclude '.gitignore' \
      --exclude '.jobs-markdown-toc' --exclude '.jobs-workbuddy-managed.json' \
      "${REPO_SKILLS_DIR}/${name}/" "${STAGING_SKILLS}/${name}/" || {
        error_echo "复制失败：${name}"
        return 1
      }
    rewrite_skill_tree "${STAGING_SKILLS}/${name}"
  done
  success_echo "临时区准备完成：${#SKILL_NAMES} 个技能包。"
}
# 对技能包内的文本文件做路径与措辞改写，二进制与资源文件原样保留。
rewrite_skill_tree() {
  local root="$1" file
  /usr/bin/find "$root" -type f \( -name '*.md' -o -name '*.yaml' -o -name '*.yml' -o -name '*.zsh' -o -name '*.sh' -o -name '*.command' -o -name '*.py' \) -print0 |
    while IFS= read -r -d '' file; do
      rewrite_text_file "$file"
    done
}
# 单文件改写：先修文档仓库根，再修用户目录，最后只动指代执行主体的 Codex 短语。
rewrite_text_file() {
  local file="$1"
  JOBS_OLD_HOME="$HOME_OLD" JOBS_NEW_HOME="$HOME" JOBS_DOCS_HOST="$DOCS_HOST_DIR" \
    /usr/bin/perl -pi -e '
      BEGIN {
        $old  = $ENV{JOBS_OLD_HOME};
        $new  = $ENV{JOBS_NEW_HOME};
        $host = $ENV{JOBS_DOCS_HOST};
      }
      s{\Q$old\E/Documents/Github}{$new/Documents/$host}g;
      s{\Q$old\E(?![A-Za-z0-9_.-])}{$new}g;
      s{最近 Codex 任务和 `~/.codex/memories`}{最近 WorkBuddy 任务和 `~/.workbuddy/memory`}g;
      s{Codex 需要}{WorkBuddy 需要}g;
      s{Codex 跨项目}{WorkBuddy 跨项目}g;
      s{Codex 负责}{WorkBuddy 负责}g;
      s{Use when Codex needs}{Use when WorkBuddy needs}g;
    ' "$file" || warn_echo "改写失败，保留原文：${file}"
}
# 渲染全局规约：把 ${HOME} 占位替换为当前用户目录，供记忆块与全局技能共用。
render_global_documents() {
  if (( SKILLS_ONLY )); then
    note_echo "按 --skills-only 跳过全局规约渲染。"
    return 0
  fi
  info_echo "渲染全局规约镜像。"
  /bin/mkdir -p "${STAGING_ROOT}/${GLOBAL_SKILL_NAME}"
  /usr/bin/perl -pe 's/\$\{HOME\}/$ENV{HOME}/g' "$GLOBAL_SOURCE" > "$RENDERED_GLOBAL" || {
    error_echo "渲染失败：${GLOBAL_SOURCE}"
    return 1
  }
  {
    print -r -- "$START_MARKER"
    print -r -- ""
    /bin/cat "$RENDERED_GLOBAL"
    print -r -- ""
    print -r -- "$END_MARKER"
  } > "$MEMORY_BLOCK"
  {
    print -r -- "---"
    print -r -- "name: ${GLOBAL_SKILL_NAME}"
    print -r -- "description: 当任务需要遵循 Jobs 全局工作规约（默认称呼、中文沟通、代码归属边界、前端回退、图片素材来源、Skills 加载原则、固定项目路径、CodeGraph 使用）时使用；是 💻JobsCodexConfigs/AGENTS.md 的 WorkBuddy 镜像，与个人 MEMORY.md 常驻块同源。"
    print -r -- "---"
    print -r -- ""
    /bin/cat "$RENDERED_GLOBAL"
  } > "$GLOBAL_SKILL_FILE"
  check_memory_budget || return 1
  success_echo "全局规约渲染完成：记忆块 $(wc -l < "$MEMORY_BLOCK" | tr -d ' ') 行。"
}
# 预估写入后 MEMORY.md 总行数；超过 WorkBuddy 200 行截断阈值就拒绝写入。
check_memory_budget() {
  local outside_lines block_lines total
  outside_lines=$(count_outside_lines)
  block_lines=$(wc -l < "$MEMORY_BLOCK" | tr -d ' ')
  total=$(( outside_lines + block_lines + 1 ))
  gray_echo "MEMORY.md 现有块外内容 ${outside_lines} 行，写入后约 ${total} 行（上限 200 行）。"
  if (( total > 200 )); then
    error_echo "写入后将超过 200 行截断阈值，已停止；请精简 workbuddy/AGENTS.workbuddy.md。"
    return 1
  fi
}
# 统计 MEMORY.md 中受管块之外的行数，用于行数预算与重建。
count_outside_lines() {
  [[ -f "$MEMORY_FILE" ]] || { print -r -- 0; return 0; }
  /usr/bin/awk -v s="$BEGIN_MARK_QUERY" -v e="$END_MARK_QUERY" '
    index($0,s){skip=1;next}
    index($0,e){skip=0;next}
    !skip{count++}
    END{print count+0}
  ' "$MEMORY_FILE"
}
# 逐项打印将发生的变更；预览只读，不创建备份、不写目标。
show_change_preview() {
  local name target action
  highlight_echo "====================== 变更预览 ======================"
  if (( ! GLOBAL_ONLY )); then
    for name in "${SKILL_NAMES[@]}"; do
      target="${SKILLS_TARGET}/${name}"
      action="$(describe_skill_action "$target")"
      gray_echo "技能 ${name} → ${target}（${action}）"
    done
    target="${SKILLS_TARGET}/${GLOBAL_SKILL_NAME}"
    gray_echo "全局技能 ${GLOBAL_SKILL_NAME} → ${target}（$(describe_skill_action "$target")）"
  else
    gray_echo "按 --global-only 跳过其它技能。"
  fi
  if (( ! SKILLS_ONLY )); then
    gray_echo "全局规约 → ${MEMORY_FILE} 的受管块（保留块外内容）"
  else
    gray_echo "按 --skills-only 跳过 MEMORY.md 受管块。"
  fi
  gray_echo "备份目录 → ${BACKUP_ROOT}/<时间戳>（dry-run 不创建）"
  highlight_echo "======================================================"
}
# 判断单个技能目录的写入动作，用于预览与保护。
describe_skill_action() {
  local target="$1"
  if [[ ! -d "$target" ]]; then
    print -r -- "新建"
  elif [[ -f "${target}/.jobs-workbuddy-managed.json" ]]; then
    print -r -- "覆盖受管副本"
  elif (( FORCE_SKILLS )); then
    print -r -- "覆盖非受管目录（--force-skills）"
  else
    print -r -- "跳过：非本脚本托管，需 --force-skills"
  fi
}
# 危险动作确认；dry-run 与 --yes 直接通过，其余必须输入 YES。
confirm_apply() {
  local answer=""
  if (( DRY_RUN )); then
    note_echo "dry-run：跳过写入确认。"
    return 0
  fi
  if (( ASSUME_YES )); then
    note_echo "已指定 --yes，直接执行写入。"
    return 0
  fi
  echo ""
  read -r "?👉 确认写入 WorkBuddy 配置请输入 YES（其它输入取消）：" answer
  if [[ "$answer" != "YES" ]]; then
    warn_echo "未输入 YES，已取消，未修改任何目标。"
    return 1
  fi
}
# 覆盖前备份将被改动的技能目录与 MEMORY.md，保留可恢复副本。
backup_existing() {
  local name target
  if (( DRY_RUN )); then
    note_echo "dry-run：跳过备份。"
    return 0
  fi
  BACKUP_DIR="${BACKUP_ROOT}/$(date '+%Y%m%d-%H%M%S')"
  /bin/mkdir -p "$BACKUP_DIR" || { error_echo "创建备份目录失败：${BACKUP_DIR}"; return 1; }
  for name in "${SKILL_NAMES[@]}" "$GLOBAL_SKILL_NAME"; do
    target="${SKILLS_TARGET}/${name}"
    [[ -d "$target" ]] || continue
    /usr/bin/rsync -a "${target}/" "${BACKUP_DIR}/skills/${name}/" || {
      error_echo "备份失败：${target}"
      return 1
    }
  done
  if [[ -f "$MEMORY_FILE" ]]; then
    /bin/cp -p "$MEMORY_FILE" "${BACKUP_DIR}/MEMORY.md" || { error_echo "备份 MEMORY.md 失败。"; return 1; }
  fi
  success_echo "备份完成：${BACKUP_DIR}"
}
# 把临时区技能部署到 WorkBuddy，并写入托管标记；非托管目录默认跳过。
apply_skills() {
  local name target action
  SYNCED_SKILLS=()
  SKIPPED_SKILLS=()
  if (( DRY_RUN )); then
    note_echo "dry-run：跳过技能写入。"
    return 0
  fi
  if (( GLOBAL_ONLY )); then
    note_echo "按 --global-only 跳过其它技能写入。"
    return 0
  fi
  for name in "${SKILL_NAMES[@]}"; do
    target="${SKILLS_TARGET}/${name}"
    action="$(describe_skill_action "$target")"
    if [[ "$action" == 跳过* ]]; then
      warn_echo "跳过 ${name}：${action}"
      SKIPPED_SKILLS+=("$name")
      continue
    fi
    /bin/mkdir -p "$target" || { error_echo "创建目录失败：${target}"; return 1; }
    /usr/bin/rsync -a --delete "${STAGING_SKILLS}/${name}/" "${target}/" || {
      error_echo "写入失败：${target}"
      return 1
    }
    write_managed_marker "$target" "skills/${name}"
    SYNCED_SKILLS+=("$name")
  done
  success_echo "技能写入完成：${#SYNCED_SKILLS} 个；跳过 ${#SKIPPED_SKILLS} 个。"
}
# 写入托管标记，记录来源、仓库提交与同步时间，作为下次覆盖的凭据。
write_managed_marker() {
  local target="$1" rel_source="$2"
  {
    print -r -- "{"
    print -r -- "  \"managedBy\": \"JobsCodexConfigs\","
    print -r -- "  \"source\": \"${rel_source}\","
    print -r -- "  \"repoCommit\": \"${REPO_COMMIT}\","
    print -r -- "  \"syncedAt\": \"$(date '+%Y-%m-%dT%H:%M:%S%z')\","
    print -r -- "  \"generator\": \"【MacOS】同步Codex配置到WorkBuddy.command\""
    print -r -- "}"
  } > "${target}/.jobs-workbuddy-managed.json"
}
# 写入 MEMORY.md 受管块与全局技能；块外内容逐行保留，不重排用户已有记忆。
apply_global_documents() {
  if (( SKILLS_ONLY )); then
    note_echo "按 --skills-only 跳过全局规约写入。"
    return 0
  fi
  if (( DRY_RUN )); then
    note_echo "dry-run：跳过 MEMORY.md 与全局技能写入。"
    return 0
  fi
  replace_memory_block || return 1
  /bin/mkdir -p "${SKILLS_TARGET}/${GLOBAL_SKILL_NAME}" || { error_echo "创建全局技能目录失败。"; return 1; }
  /bin/cp "$GLOBAL_SKILL_FILE" "${SKILLS_TARGET}/${GLOBAL_SKILL_NAME}/SKILL.md" || { error_echo "写入全局技能失败。"; return 1; }
  write_managed_marker "${SKILLS_TARGET}/${GLOBAL_SKILL_NAME}" "workbuddy/AGENTS.workbuddy.md"
  success_echo "全局规约写入完成。"
}
# 用受管块替换 MEMORY.md 中的旧块；无旧块则追加到文件末尾。
replace_memory_block() {
  local outside="${STAGING_ROOT}/memory.outside.md" merged="${STAGING_ROOT}/memory.merged.md"
  if [[ -f "$MEMORY_FILE" ]]; then
    /usr/bin/awk -v s="$BEGIN_MARK_QUERY" -v e="$END_MARK_QUERY" '
      index($0,s){skip=1;next}
      index($0,e){skip=0;next}
      !skip{print}
    ' "$MEMORY_FILE" > "$outside" || { error_echo "读取 MEMORY.md 失败。"; return 1; }
  else
    : > "$outside"
  fi
  /usr/bin/perl -0pe 's/[ \t\r]*\n+\z/\n/' "$outside" > "$merged" || { error_echo "整理 MEMORY.md 块外内容失败。"; return 1; }
  [[ -s "$merged" ]] && print -r -- "" >> "$merged"
  /bin/cat "$MEMORY_BLOCK" >> "$merged"
  /bin/cp "$merged" "$MEMORY_FILE" || { error_echo "写入 MEMORY.md 失败：${MEMORY_FILE}"; return 1; }
}
# 校验写入结果：技能可解析、无残留旧路径、记忆块存在且行数未超限。
verify_result() {
  local name target skill_file leaked="" missing=0
  if (( DRY_RUN )); then
    note_echo "dry-run：跳过结果校验。"
    return 0
  fi
  info_echo "开始校验写入结果。"
  for name in "${SYNCED_SKILLS[@]}" "$GLOBAL_SKILL_NAME"; do
    skill_file="${SKILLS_TARGET}/${name}/SKILL.md"
    [[ -f "$skill_file" ]] || { [[ "$name" == "$GLOBAL_SKILL_NAME" ]] && (( SKILLS_ONLY )) && continue; error_echo "缺少 SKILL.md：${skill_file}"; missing=1; continue; }
    /usr/bin/head -20 "$skill_file" | /usr/bin/grep -q '^name:' || { error_echo "frontmatter 缺少 name：${name}"; missing=1; }
    /usr/bin/head -20 "$skill_file" | /usr/bin/grep -q '^description:' || { error_echo "frontmatter 缺少 description：${name}"; missing=1; }
  done
  for name in "${SYNCED_SKILLS[@]}" "$GLOBAL_SKILL_NAME"; do
    target="${SKILLS_TARGET}/${name}"
    [[ -d "$target" ]] || continue
    leaked="$(/usr/bin/grep -rFl "$HOME_OLD" "$target" 2>/dev/null | /usr/bin/head -3 | tr '\n' ' ')"
    [[ -z "$leaked" ]] || { error_echo "目标仍有 ${HOME_OLD} 残留路径：${name} → ${leaked}"; missing=1; }
  done
  if (( ! SKILLS_ONLY )); then
    if ! /usr/bin/grep -qF "$BEGIN_MARK_QUERY" "$MEMORY_FILE" 2>/dev/null; then
      error_echo "MEMORY.md 未写入受管块。"
      missing=1
    fi
    if (( $(wc -l < "$MEMORY_FILE" | tr -d ' ') > 200 )); then
      error_echo "MEMORY.md 已超过 200 行，末尾规则会被截断。"
      missing=1
    fi
    [[ -f "${SKILLS_TARGET}/${GLOBAL_SKILL_NAME}/SKILL.md" ]] || { error_echo "缺少全局技能 ${GLOBAL_SKILL_NAME}。"; missing=1; }
  fi
  if (( missing )); then
    VERIFY_FAILED=1
    error_echo "校验未通过；可用 ${BACKUP_DIR} 恢复。"
    return 1
  fi
  success_echo "校验通过：技能可解析、无残留路径、记忆块行数合规。"
}
# 汇总同步数量、残余 Codex 措辞与生效提示。
print_summary() {
  local remaining
  highlight_echo "====================== 同步结果 ======================"
  if (( DRY_RUN )); then
    note_echo "dry-run 结束：未写入任何目标。"
  else
    if (( ${#SYNCED_SKILLS} )); then
      success_echo "已同步技能：${#SYNCED_SKILLS} 个（${(j:、:)SYNCED_SKILLS}）"
    else
      warn_echo "本次没有写入任何技能。"
    fi
    if (( ${#SKIPPED_SKILLS} )); then
      warn_echo "已跳过技能：${(j:、:)SKIPPED_SKILLS}（非托管目录，需 --force-skills）"
    fi
    success_echo "全局规约：${MEMORY_FILE}（受管块）"
    success_echo "备份目录：${BACKUP_DIR}"
  fi
  remaining=$(/usr/bin/grep -rFo 'Codex' "$STAGING_SKILLS" 2>/dev/null | wc -l | tr -d ' ')
  gray_echo "临时区保留 Codex 字样 ${remaining} 处；预期为 JobsCodexConfigs / JobsCodexMemory / openai.com/codex 等专有名词，如需处理请改源仓库。"
  gray_echo "生效方式：新开一个 WorkBuddy 对话；技能列表有缓存，必要时重启客户端。"
  gray_echo "日志位置：${LOG_FILE}"
  highlight_echo "======================================================"
  (( VERIFY_FAILED )) && return 1
  return 0
}
# 编排脚本自述、前置检查、预览确认与写入校验。
main() {
  init_runtime # 初始化日志、路径变量与中断恢复提示。
  parse_args "$@" # 解析 --dry-run / --yes / --global-only 等入口参数。
  show_script_intro_and_wait # 打印内置自述并等待回车，防止误触后直接写用户配置。
  check_environment # 校验源文件、目标目录与依赖命令，并提示配置漂移。
  prepare_staging # 复制技能包到临时区并完成路径与措辞改写。
  render_global_documents # 渲染全局规约镜像，生成记忆块与全局技能正文。
  show_change_preview # 逐项打印将写入的目标与动作。
  confirm_apply # 危险动作要求输入 YES；dry-run 直接通过。
  backup_existing # 覆盖前备份技能目录与 MEMORY.md。
  apply_skills # 部署用户级技能并写入托管标记。
  apply_global_documents # 写入 MEMORY.md 受管块与全局技能。
  verify_result # 校验可解析性、残留路径与行数上限。
  print_summary # 汇总同步结果、残余措辞与生效提示。
}

main "$@"
