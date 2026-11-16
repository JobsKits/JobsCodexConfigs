#!/bin/zsh
# 脚本自述：
# - 脚本名称：【MacOS】同步Codex配置到WorkBuddy.command
# - 核心用途：把本仓库的全局工作规约与用户级 Skills 单向同步到 WorkBuddy。
# - 影响范围：写入 ~/.workbuddy/skills/<skill>/ 与个人 MEMORY.md 受管块；不改 config.toml、不改 ~/.codex、不改本仓库。
# - 运行提示：运行后先打印内置自述并等待回车；预览变更后输入 YES 才执行，Ctrl+C 可取消。

# >>> Jobs terminal style protection v1 >>>
# 临时保护当前终端配色，业务进程自行管理原有退出清理。
jobs_terminal_style_run() {
    # 无法可靠保存原色时，沿用脚本已有的纯文本约定。
    jobs_terminal_style_plain() {
        PLAIN_OUTPUT=1
        NO_COLOR=1
        FORCE_COLOR=0
        CLICOLOR=0
        ANSI_COLORS_DISABLED=1
        npm_config_color=false
        export PLAIN_OUTPUT NO_COLOR FORCE_COLOR CLICOLOR ANSI_COLORS_DISABLED npm_config_color
        if "$@"; then
            jobs_style_exit_status=0
        else
            jobs_style_exit_status=$?
        fi
        exit "$jobs_style_exit_status"
    }
    if [ ! -t 0 ] || [ ! -t 1 ] || [ -z "${TERM:-}" ] ||
       [ "${TERM:-}" = dumb ] || [ "${NO_COLOR+x}" = x ] ||
       [ "${PLAIN_OUTPUT:-0}" = 1 ] || [ "${IS_SOURCETREE_RUNTIME:-0}" = 1 ] ||
       env | LC_ALL=C grep -qiE '^(SOURCETREE|SOURCE_TREE)'; then
        if "$@"; then
            jobs_style_exit_status=0
        else
            jobs_style_exit_status=$?
        fi
        exit "$jobs_style_exit_status"
    fi
    if [ -n "${TMUX:-}${STY:-}" ]; then
        jobs_terminal_style_plain "$@"
    fi
    jobs_style_tty=$(tty 2>/dev/null) || jobs_terminal_style_plain "$@"
    if ! ps -o pgid= -o tpgid= -p "$$" 2>/dev/null |
         LC_ALL=C awk 'NF == 2 && $1 == $2 && $1 > 0 { foreground = 1 } END { exit !foreground }'; then
        jobs_terminal_style_plain "$@"
    fi
    case ${JOBS_TERMINAL_STYLE_OWNER:-} in
        ''|*[!0-9]*) ;;
        *)
            if [ "${JOBS_TERMINAL_STYLE_TTY:-}" = "$jobs_style_tty" ] &&
               kill -0 "$JOBS_TERMINAL_STYLE_OWNER" 2>/dev/null; then
                if "$@"; then
                    jobs_style_exit_status=0
                else
                    jobs_style_exit_status=$?
                fi
                exit "$jobs_style_exit_status"
            fi
            ;;
    esac
    jobs_style_stty=$(stty -g 2>/dev/null < /dev/tty) || jobs_terminal_style_plain "$@"
    jobs_style_saved=''
    jobs_style_saved_rows=''
    jobs_style_original_rows=''
    jobs_style_applied_rows=''
    jobs_style_changed=0
    jobs_style_applied_complete=0
    jobs_style_query_active=0
    jobs_style_recovery=''
    jobs_style_exit_status=0
    jobs_style_esc=$(printf '\033')
    jobs_style_bel=$(printf '\007')
    # 完整颜色帧有界重发；设置核验与退出恢复容忍帧外回车和明确方向键。
    jobs_terminal_style_query() {
        jobs_style_query_key=$1
        jobs_style_reply=''
        jobs_style_query_buffer=''
        jobs_style_query_target_reply=''
        jobs_style_query_target_normalized=''
        jobs_style_query_target_rgb=''
        jobs_style_query_st="${jobs_style_esc}\\"
        jobs_style_query_stale_count=0
        jobs_style_query_phase=${2:-strict}
        jobs_style_query_cr=$(printf '\r')
        jobs_style_query_lf=$(printf '\n.')
        jobs_style_query_lf=${jobs_style_query_lf%.}
        jobs_style_query_failure='未收到目标颜色的完整答复（最多 3 次查询，每次约 2 秒）'
        for jobs_style_query_round in 1 2 3; do
            printf '\033]%s;?\007' "$jobs_style_query_key" > /dev/tty || {
                jobs_style_query_failure='无法向原终端发送配色查询'
                return 1
            }
            for jobs_style_attempt in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
                # 哨兵保留末尾换行，不能把只有回车的键盘输入误当成无答复。
                jobs_style_piece=$(dd bs=256 count=1 2>/dev/null < /dev/tty; printf '.')
                jobs_style_piece=${jobs_style_piece%.}
                jobs_style_query_buffer=$jobs_style_query_buffer$jobs_style_piece
                while [ -n "$jobs_style_query_buffer" ]; do
                    # 设置核验与退出恢复阶段允许帧外的明确控制键，普通文字仍然失败。
                    if [ "$jobs_style_query_phase" = cleanup ] || [ "$jobs_style_query_phase" = applied ]; then
                        jobs_style_query_control_sequence=''
                        jobs_style_query_control_partial=0
                        case $jobs_style_query_buffer in
                            "$jobs_style_query_cr"*) jobs_style_query_control_sequence=$jobs_style_query_cr ;;
                            "$jobs_style_query_lf"*) jobs_style_query_control_sequence=$jobs_style_query_lf ;;
                        esac
                        if [ -z "$jobs_style_query_control_sequence" ]; then
                            for jobs_style_query_direction in A B C D; do
                                for jobs_style_query_control_candidate in \
                                    "${jobs_style_esc}[${jobs_style_query_direction}" \
                                    "${jobs_style_esc}O${jobs_style_query_direction}" \
                                    "${jobs_style_esc}[1;2${jobs_style_query_direction}" \
                                    "${jobs_style_esc}[1;3${jobs_style_query_direction}" \
                                    "${jobs_style_esc}[1;4${jobs_style_query_direction}" \
                                    "${jobs_style_esc}[1;5${jobs_style_query_direction}" \
                                    "${jobs_style_esc}[1;6${jobs_style_query_direction}" \
                                    "${jobs_style_esc}[1;7${jobs_style_query_direction}" \
                                    "${jobs_style_esc}[1;8${jobs_style_query_direction}"; do
                                    case $jobs_style_query_buffer in
                                        "$jobs_style_query_control_candidate"*)
                                            jobs_style_query_control_sequence=$jobs_style_query_control_candidate
                                            break 2
                                            ;;
                                    esac
                                    case $jobs_style_query_control_candidate in
                                        "$jobs_style_query_buffer"*) jobs_style_query_control_partial=1 ;;
                                    esac
                                done
                            done
                        fi
                        if [ -n "$jobs_style_query_control_sequence" ]; then
                            jobs_style_phase_control_keys=$(( ${jobs_style_phase_control_keys:-0} + 1 ))
                            if [ "$jobs_style_phase_control_keys" -gt 64 ]; then
                                jobs_style_query_failure='本阶段已识别控制键超过 64 个，已停止自动恢复'
                                return 1
                            fi
                            jobs_style_query_buffer=${jobs_style_query_buffer#"$jobs_style_query_control_sequence"}
                            continue
                        fi
                        if [ "$jobs_style_query_control_partial" = 1 ]; then
                            break
                        fi
                    fi
                    case $jobs_style_query_buffer in
                        "$jobs_style_esc"|"$jobs_style_esc]") break ;;
                        "$jobs_style_esc]"*) ;;
                        *) jobs_style_query_failure='收到非配色查询输入，已停止读取'; return 1 ;;
                    esac
                    jobs_style_query_head=''
                    jobs_style_query_terminator=''
                    case $jobs_style_query_buffer in
                        *"$jobs_style_bel"*)
                            jobs_style_query_head=${jobs_style_query_buffer%%"$jobs_style_bel"*}
                            jobs_style_query_terminator=$jobs_style_bel
                            ;;
                    esac
                    case $jobs_style_query_buffer in
                        *"$jobs_style_query_st"*)
                            jobs_style_query_st_head=${jobs_style_query_buffer%%"$jobs_style_query_st"*}
                            if [ -z "$jobs_style_query_terminator" ] ||
                               [ "${#jobs_style_query_st_head}" -lt "${#jobs_style_query_head}" ]; then
                                jobs_style_query_head=$jobs_style_query_st_head
                                jobs_style_query_terminator=$jobs_style_query_st
                            fi
                            ;;
                    esac
                    [ -n "$jobs_style_query_terminator" ] || break
                    jobs_style_query_frame=$jobs_style_query_head$jobs_style_query_terminator
                    jobs_style_query_buffer=${jobs_style_query_buffer#"$jobs_style_query_frame"}
                    jobs_style_query_body=${jobs_style_query_head#"$jobs_style_esc]"}
                    case $jobs_style_query_body in
                        *';rgb:'*) ;;
                        *) jobs_style_query_failure='配色答复格式或 RGB 数据无效'; return 1 ;;
                    esac
                    jobs_style_query_frame_key=${jobs_style_query_body%%';rgb:'*}
                    case $jobs_style_query_frame_key in
                        10|11|12|'4;'[0-9]|'4;1'[0-5]) ;;
                        *) jobs_style_query_failure='收到不属于本次颜色协议的答复'; return 1 ;;
                    esac
                    jobs_style_query_frame_rgb=${jobs_style_query_body#"$jobs_style_query_frame_key;rgb:"}
                    jobs_style_query_frame_normalized=$(printf '%s\n' "$jobs_style_query_frame_rgb" | LC_ALL=C awk -F/ '
                        BEGIN { valid = 1 }
                        NR != 1 || NF != 3 { valid = 0; exit }
                        {
                            for (i = 1; i <= 3; i++) {
                                h = tolower($i)
                                if (length(h) < 1 || length(h) > 4 || h ~ /[^0-9a-f]/) {
                                    valid = 0
                                    exit
                                }
                                n = 0
                                for (j = 1; j <= length(h); j++) n = n * 16 + index("0123456789abcdef", substr(h, j, 1)) - 1
                                value[i] = int(n * 65535 / (16 ^ length(h) - 1) + 0.5)
                            }
                        }
                        END {
                            if (!valid || NR != 1) exit 1
                            printf "%d/%d/%d", value[1], value[2], value[3]
                        }
                    ')
                    if [ -z "$jobs_style_query_frame_normalized" ]; then
                        jobs_style_query_failure='配色答复格式或 RGB 数据无效'
                        return 1
                    fi
                    if [ "$jobs_style_query_frame_key" = "$jobs_style_query_key" ]; then
                        if [ -n "$jobs_style_query_target_reply" ] &&
                           [ "$jobs_style_query_target_normalized" != "$jobs_style_query_frame_normalized" ]; then
                            jobs_style_query_failure='同一颜色的重复答复不一致，已停止自动恢复'
                            return 1
                        fi
                        jobs_style_query_target_reply=$jobs_style_query_frame
                        jobs_style_query_target_normalized=$jobs_style_query_frame_normalized
                        jobs_style_query_target_rgb=$jobs_style_query_frame_rgb
                    else
                        jobs_style_query_stale_count=$((jobs_style_query_stale_count + 1))
                        if [ "$jobs_style_query_stale_count" -gt 128 ]; then
                            jobs_style_query_failure='收到过多旧颜色答复，已停止读取'
                            return 1
                        fi
                    fi
                done
                if [ -n "$jobs_style_query_target_reply" ] && [ -z "$jobs_style_query_buffer" ]; then
                    jobs_style_reply=$jobs_style_query_target_reply
                    jobs_style_normalized=$jobs_style_query_target_normalized
                    jobs_style_rgb=$jobs_style_query_target_rgb
                    return 0
                fi
            done
            # 残缺帧不能通过重发拼成另一个答复，更不能被当成键盘空输入。
            if [ -n "$jobs_style_query_buffer" ]; then
                jobs_style_query_failure='配色答复帧不完整，已停止自动恢复'
                return 1
            fi
        done
        return 1
    }
    # 查询可用不代表终端允许改色，按目标值核对实际生效结果。
    jobs_terminal_style_accepts_target() {
        jobs_style_requested_hex=''
        case $1 in
            10|12) jobs_style_requested_hex=ffffff ;;
            11) jobs_style_requested_hex=000000 ;;
            '4;'*)
                jobs_style_requested_index=0
                for jobs_style_requested_color in 000000 ff5f56 5fd787 ffd75f 5fafff d787ff 5fd7ff eeeeee 9e9e9e ff8787 87ffaf ffff87 87bfff ffafff afffff ffffff; do
                    if [ "4;$jobs_style_requested_index" = "$1" ]; then
                        jobs_style_requested_hex=$jobs_style_requested_color
                        break
                    fi
                    jobs_style_requested_index=$((jobs_style_requested_index + 1))
                done
                ;;
        esac
        [ -n "$jobs_style_requested_hex" ] || return 1
        printf '%s|%s\n' "$jobs_style_normalized" "$jobs_style_requested_hex" | LC_ALL=C awk -F'|' '
            function hexbyte(h) {
                return (index("0123456789abcdef", substr(h, 1, 1)) - 1) * 16 + index("0123456789abcdef", substr(h, 2, 1)) - 1
            }
            {
                if (split($1, actual, "/") != 3 || length($2) != 6) exit 1
                for (i = 1; i <= 3; i++) {
                    difference = actual[i] - hexbyte(substr($2, i * 2 - 1, 2)) * 257
                    if (difference < -255 || difference > 255) exit 1
                }
            }
        '
    }
    # 核验中断时重新读取当前值，只撤回仍等于本轮目标值的颜色。
    jobs_terminal_style_rollback() {
        jobs_style_rollback_issue='无法读取或设置原终端输入模式'
        jobs_style_rollback_safe=''
        jobs_style_rollback_conflicts=''
        jobs_style_phase_control_keys=0
        jobs_style_stty=$(stty -g 2>/dev/null < /dev/tty) || jobs_style_stty=''
        if [ -n "$jobs_style_stty" ] && stty -echo -icanon min 0 time 1 2>/dev/null < /dev/tty; then
            jobs_style_query_active=1
            jobs_style_rollback_ok=1
            while IFS='|' read -r jobs_style_key jobs_style_original_normalized jobs_style_original; do
                [ -n "$jobs_style_key" ] || continue
                if ! jobs_terminal_style_query "$jobs_style_key" cleanup; then
                    jobs_style_rollback_ok=0
                    jobs_style_rollback_issue="回退颜色项 $jobs_style_key：$jobs_style_query_failure"
                    break
                fi
                if [ "$jobs_style_normalized" = "$jobs_style_original_normalized" ]; then
                    continue
                elif jobs_terminal_style_accepts_target "$jobs_style_key"; then
                    jobs_style_rollback_safe=$jobs_style_rollback_safe$jobs_style_original
                else
                    jobs_style_rollback_conflicts="$jobs_style_rollback_conflicts $jobs_style_key"
                fi
            done <<JOBS_STYLE_ROLLBACK
$jobs_style_original_rows
JOBS_STYLE_ROLLBACK
            stty "$jobs_style_stty" 2>/dev/null < /dev/tty || { jobs_style_rollback_ok=0; jobs_style_rollback_issue='无法恢复原终端输入模式'; }
            jobs_style_query_active=0
            if [ "$jobs_style_rollback_ok" = 1 ] && printf '%s\033[0m' "$jobs_style_rollback_safe" > /dev/tty; then
                if [ -z "$jobs_style_rollback_conflicts" ]; then
                    rm -f "$jobs_style_recovery"
                    rmdir "${jobs_style_recovery%/*}" 2>/dev/null || :
                    return 0
                fi
                printf '检测到运行期间的配色变更，已保留这些项：%s\n' "$jobs_style_rollback_conflicts" >&2
                jobs_style_rollback_issue="核验中断后检测到其它配色变更：$jobs_style_rollback_conflicts"
            fi
        fi
        printf '终端配色未能安全自动恢复（%s）；确认覆盖当前配色后可运行：sh "%s"\n' "$jobs_style_rollback_issue" "$jobs_style_recovery" >&2
        return 1
    }
    # 检测到后续改色时只恢复仍由本次保护持有的项，保留独立恢复入口。
    jobs_terminal_style_cleanup() {
        jobs_style_result=$1
        trap '' HUP INT TERM
        if [ "$jobs_style_query_active" = 1 ]; then
            stty "$jobs_style_stty" 2>/dev/null < /dev/tty || :
            jobs_style_query_active=0
        fi
        if [ "$jobs_style_changed" = 1 ] && [ "$jobs_style_applied_complete" != 1 ]; then
            if jobs_terminal_style_rollback; then
                jobs_style_changed=0
            else
                [ "$jobs_style_result" -ne 0 ] || jobs_style_result=1
            fi
            if [ "${2:-}" = continue ]; then
                jobs_style_cleanup_status=$jobs_style_result
                return 0
            fi
            exit "$jobs_style_result"
        fi
        if [ "$jobs_style_changed" = 1 ]; then
            jobs_style_cleanup_ok=0
            jobs_style_cleanup_issue='无法读取或设置原终端输入模式，或临时配色未完成核验'
            jobs_style_conflicts=''
            jobs_style_restore_safe=''
            jobs_style_phase_control_keys=0
            if [ "$jobs_style_applied_complete" = 1 ]; then
                jobs_style_stty=$(stty -g 2>/dev/null < /dev/tty) || jobs_style_stty=''
                if [ -n "$jobs_style_stty" ] && stty -echo -icanon min 0 time 1 2>/dev/null < /dev/tty; then
                    jobs_style_query_active=1
                    jobs_style_cleanup_ok=1
                    while IFS='|' read -r jobs_style_key jobs_style_expected jobs_style_original; do
                        [ -n "$jobs_style_key" ] || continue
                        if ! jobs_terminal_style_query "$jobs_style_key" cleanup; then
                            jobs_style_cleanup_ok=0
                            jobs_style_cleanup_issue="颜色项 $jobs_style_key：$jobs_style_query_failure"
                            break
                        fi
                        if [ "$jobs_style_normalized" = "$jobs_style_expected" ]; then
                            jobs_style_restore_safe=$jobs_style_restore_safe$jobs_style_original
                        else
                            jobs_style_conflicts="$jobs_style_conflicts $jobs_style_key"
                        fi
                    done <<JOBS_STYLE_APPLIED
$jobs_style_applied_rows
JOBS_STYLE_APPLIED
                    stty "$jobs_style_stty" 2>/dev/null < /dev/tty || { jobs_style_cleanup_ok=0; jobs_style_cleanup_issue='无法恢复原终端输入模式'; }
                    jobs_style_query_active=0
                fi
            fi
            if [ "$jobs_style_cleanup_ok" = 1 ] && printf '%s\033[0m' "$jobs_style_restore_safe" > /dev/tty; then
                if [ -z "$jobs_style_conflicts" ]; then
                    rm -f "$jobs_style_recovery"
                    rmdir "${jobs_style_recovery%/*}" 2>/dev/null || :
                else
                    printf '检测到运行期间的配色变更，已保留这些项：%s\n' "$jobs_style_conflicts" >&2
                    printf '确认要覆盖后续改色时才使用恢复入口：sh "%s"\n' "$jobs_style_recovery" >&2
                    [ "$jobs_style_result" -ne 0 ] || jobs_style_result=1
                fi
            else
                printf '终端配色未能安全自动恢复（%s）；确认覆盖当前配色后可运行：sh "%s"\n' "$jobs_style_cleanup_issue" "$jobs_style_recovery" >&2
                [ "$jobs_style_result" -ne 0 ] || jobs_style_result=1
            fi
        fi
        if [ "${2:-}" = continue ]; then
            jobs_style_cleanup_status=$jobs_style_result
            return 0
        fi
        exit "$jobs_style_result"
    }
    trap 'jobs_terminal_style_cleanup "$jobs_style_exit_status"' 0
    trap 'jobs_style_exit_status=129; jobs_terminal_style_cleanup 129 continue; jobs_style_changed=0; exit 129' HUP
    trap 'jobs_style_exit_status=130; jobs_terminal_style_cleanup 130 continue; jobs_style_changed=0; exit 130' INT
    trap 'jobs_style_exit_status=143; jobs_terminal_style_cleanup 143 continue; jobs_style_changed=0; exit 143' TERM
    if ! stty -echo -icanon min 0 time 1 2>/dev/null < /dev/tty; then
        jobs_terminal_style_plain "$@"
    fi
    jobs_style_query_active=1
    jobs_style_probe_ok=1
    for jobs_style_key in 10 11 12 '4;0' '4;1' '4;2' '4;3' '4;4' '4;5' '4;6' '4;7' '4;8' '4;9' '4;10' '4;11' '4;12' '4;13' '4;14' '4;15'; do
        if ! jobs_terminal_style_query "$jobs_style_key"; then
            jobs_style_probe_ok=0
            break
        fi
        jobs_style_saved=$jobs_style_saved$jobs_style_reply
        jobs_style_original_rows="$jobs_style_original_rows$jobs_style_key|$jobs_style_normalized|$jobs_style_reply
"
        jobs_style_saved_rows="$jobs_style_saved_rows$jobs_style_key|$jobs_style_reply
"
    done
    stty "$jobs_style_stty" 2>/dev/null < /dev/tty || { jobs_style_exit_status=1; exit 1; }
    jobs_style_query_active=0
    if [ "$jobs_style_probe_ok" != 1 ]; then
        printf '%s\n' '终端不支持完整配色保存，或启动时收到其它输入；保留原配色并使用纯文本。' >&2
        jobs_terminal_style_plain "$@"
    fi
    jobs_style_recovery_dir=$(umask 077; mktemp -d "${TMPDIR:-/tmp}/jobs-terminal-style.XXXXXX") || jobs_terminal_style_plain "$@"
    jobs_style_recovery=$jobs_style_recovery_dir/restore.sh
    if ! (umask 077; {
        printf '#!/bin/sh\n'
        printf '[ -t 0 ] && [ "$(tty)" = '\''%s'\'' ] || { printf '\''请在原终端运行恢复入口。\\n'\'' >&2; exit 1; }\n' "$jobs_style_tty"
        printf 'printf '\''本操作会覆盖此终端当前配色。确认恢复脚本启动前的配色，请输入 YES：'\'' >&2\n'
        printf 'IFS= read -r jobs_restore_choice\n[ "$jobs_restore_choice" = YES ] || exit 1\n'
        printf 'printf '\''%%s\\033[0m'\'' '\''%s'\'' > /dev/tty\n' "$jobs_style_saved"
    } > "$jobs_style_recovery"); then
        printf '%s\n' '无法保存终端配色恢复入口；保留原配色并使用纯文本。' >&2
        jobs_terminal_style_plain "$@"
    fi
    printf '正在准备本次终端临时配色；强退后恢复入口：sh "%s"\n' "$jobs_style_recovery" >&2
    jobs_style_changed=1
    printf '\033]10;#ffffff\007\033]11;#000000\007\033]12;#ffffff\007' > /dev/tty
    jobs_style_index=0
    for jobs_style_color in 000000 ff5f56 5fd787 ffd75f 5fafff d787ff 5fd7ff eeeeee 9e9e9e ff8787 87ffaf ffff87 87bfff ffafff afffff ffffff; do
        printf '\033]4;%s;#%s\007' "$jobs_style_index" "$jobs_style_color" > /dev/tty
        jobs_style_index=$((jobs_style_index + 1))
    done
    printf '\033[0m' > /dev/tty
    jobs_style_stty=$(stty -g 2>/dev/null < /dev/tty) || { jobs_style_exit_status=1; exit 1; }
    stty -echo -icanon min 0 time 1 2>/dev/null < /dev/tty || { jobs_style_exit_status=1; exit 1; }
    jobs_style_query_active=1
    jobs_style_probe_ok=1
    jobs_style_targets_ok=1
    jobs_style_phase_control_keys=0
    while IFS='|' read -r jobs_style_key jobs_style_original; do
        [ -n "$jobs_style_key" ] || continue
        if ! jobs_terminal_style_query "$jobs_style_key" applied; then
            jobs_style_probe_ok=0
            break
        fi
        jobs_style_applied_rows="$jobs_style_applied_rows$jobs_style_key|$jobs_style_normalized|$jobs_style_original
"
        if ! jobs_terminal_style_accepts_target "$jobs_style_key"; then
            jobs_style_targets_ok=0
        fi
    done <<JOBS_STYLE_ORIGINAL
$jobs_style_saved_rows
JOBS_STYLE_ORIGINAL
    stty "$jobs_style_stty" 2>/dev/null < /dev/tty || { jobs_style_exit_status=1; exit 1; }
    jobs_style_query_active=0
    if [ "$jobs_style_probe_ok" != 1 ]; then
        printf '临时配色核验失败（颜色项 %s：%s），正在核对原色恢复。\n' "$jobs_style_key" "$jobs_style_query_failure" >&2
        jobs_terminal_style_cleanup 0 continue
        jobs_style_changed=0
        if [ "$jobs_style_cleanup_status" != 0 ]; then
            jobs_style_exit_status=1
            exit 1
        fi
        trap 'jobs_style_exit_status=129; jobs_terminal_style_cleanup 129 continue; jobs_style_changed=0; exit 129' HUP
        trap 'jobs_style_exit_status=130; jobs_terminal_style_cleanup 130 continue; jobs_style_changed=0; exit 130' INT
        trap 'jobs_style_exit_status=143; jobs_terminal_style_cleanup 143 continue; jobs_style_changed=0; exit 143' TERM
        printf '%s\n' '已恢复原配色并使用纯文本。' >&2
        jobs_terminal_style_plain "$@"
    fi
    if [ "$jobs_style_targets_ok" != 1 ]; then
        jobs_terminal_style_cleanup 0 continue
        jobs_style_changed=0
        if [ "$jobs_style_cleanup_status" != 0 ]; then
            jobs_style_exit_status=1
            exit 1
        fi
        trap 'jobs_style_exit_status=129; jobs_terminal_style_cleanup 129 continue; jobs_style_changed=0; exit 129' HUP
        trap 'jobs_style_exit_status=130; jobs_terminal_style_cleanup 130 continue; jobs_style_changed=0; exit 130' INT
        trap 'jobs_style_exit_status=143; jobs_terminal_style_cleanup 143 continue; jobs_style_changed=0; exit 143' TERM
        printf '%s\n' '终端未接受本次配色，已恢复原配色并使用纯文本。' >&2
        jobs_terminal_style_plain "$@"
    fi
    jobs_style_applied_complete=1
    printf '%s\n' '本次终端已临时使用黑底白字。' >&2
    JOBS_TERMINAL_STYLE_TTY=$jobs_style_tty
    JOBS_TERMINAL_STYLE_OWNER=$$
    export JOBS_TERMINAL_STYLE_TTY JOBS_TERMINAL_STYLE_OWNER
    if "$@"; then
        jobs_style_exit_status=0
    else
        jobs_style_exit_status=$?
    fi
    exit "$jobs_style_exit_status"
}
# 仅监督直接执行的入口；被 source 时不切换配色、不重新执行业务。
jobs_terminal_style_bootstrap() {
    jobs_style_bootstrap_script=$1
    shift
    if [ -n "${ZSH_VERSION:-}" ]; then
        case ${ZSH_EVAL_CONTEXT:-} in
            *:file|*:file:*) return 0 ;;
        esac
    elif [ -n "${BASH_VERSION:-}" ] && [ "${BASH_SOURCE:-$jobs_style_bootstrap_script}" != "$jobs_style_bootstrap_script" ]; then
        return 0
    fi
    if [ "${JOBS_TERMINAL_STYLE_REEXEC:-}" = "$jobs_style_bootstrap_script" ]; then
        unset JOBS_TERMINAL_STYLE_REEXEC
        return 0
    fi
    if [ ! -t 0 ] || [ ! -t 1 ] || [ -z "${TERM:-}" ] ||
       [ "${TERM:-}" = dumb ] || [ "${NO_COLOR+x}" = x ] ||
       [ "${PLAIN_OUTPUT:-0}" = 1 ] || [ "${IS_SOURCETREE_RUNTIME:-0}" = 1 ] ||
       [ -n "${TMUX:-}${STY:-}" ] ||
       env | LC_ALL=C grep -qiE '^(SOURCETREE|SOURCE_TREE)'; then
        return 0
    fi
    case ${JOBS_TERMINAL_STYLE_OWNER:-} in
        ''|*[!0-9]*) ;;
        *)
            if kill -0 "$JOBS_TERMINAL_STYLE_OWNER" 2>/dev/null &&
               [ "${JOBS_TERMINAL_STYLE_TTY:-}" = "$(tty 2>/dev/null)" ]; then
                return 0
            fi
            ;;
    esac
    JOBS_TERMINAL_STYLE_REEXEC=$jobs_style_bootstrap_script
    export JOBS_TERMINAL_STYLE_REEXEC
    jobs_terminal_style_run /bin/zsh "$jobs_style_bootstrap_script" "$@"
    jobs_style_bootstrap_result=$?
    exit "$jobs_style_bootstrap_result"
}
jobs_terminal_style_bootstrap "$0" "$@"
# <<< Jobs terminal style protection v1 <<<

# JOBS_INPUT_CHOICE_STYLE_BEGIN
# 只展示提示选项；不读取答案、不改变默认值、返回码或业务环境。
jobs_prompt_color_ready() {
  [ -z "${NO_COLOR+x}" ] && [ -n "${TERM:-}" ] && [ "${TERM:-}" != dumb ] &&
    [ "${PLAIN_OUTPUT:-0}" != 1 ] && [ "${IS_SOURCETREE_RUNTIME:-0}" != 1 ]
}
# 原生 awk 分段着色；任意/非空输入优先，括号内外沿用同一个选项。
jobs_prompt_format() {
  /usr/bin/awk -v color="${1:-0}" -v lines="${2:-0}" -v keep="${3:-0}" '
    function typedEnter(value, start, prefix) {
      prefix = substr(value, 1, start - 1)
      gsub(/[“”‘’「」『』"]/, "", prefix)
      gsub(sprintf("%c", 39), "", prefix)
      if (prefix ~ /(空格|[Ss][Pp][Aa][Cc][Ee])[[:space:]]*(后|再|并|[Tt][Hh][Ee][Nn])?[[:space:]]*$/) return 1
      return prefix ~ /(输入|键入|填写|[Tt]ype)[^；;|]*[[:alnum:]_+-]+[[:space:]]*(后|再|并)?[[:space:]]*$/
    }
    function greenPosition(value, token, start) {
      if (match(value, /(直接|仅|只需|只|按下|按)?[[:space:]]*(回车|回車)/)) {
        start = RSTART
        return typedEnter(value, start) ? 0 : start
      }
      if (!match(value, /(^|[^[:alnum:]_])([Ee][Nn][Tt][Ee][Rr]|[Rr][Ee][Tt][Uu][Rr][Nn])([^[:alnum:]_]|$)/)) return 0
      start = RSTART
      token = substr(value, RSTART, RLENGTH)
      match(token, /[Ee][Nn][Tt][Ee][Rr]|[Rr][Ee][Tt][Uu][Rr][Nn]/)
      start += RSTART - 1
      return typedEnter(value, start) ? 0 : start
    }
    function segment(value, inherited, start, kind, prefix, body, red, green, connector, left, right, splitAt) {
      if (value == "") return value
      kind = inherited
      start = 1
      if (!kind) {
        if (match(value, /(输入)?(任意|任何)(非空)?(字符|内容|输入|键)|非空(字符|内容|输入)?|其它输入|其他输入|[Tt]ype (anything|any[^ ]*)|[Pp]ress any key/)) {
          red = RSTART
        }
        green = greenPosition(value)
        if (red && green && green < red) {
          left = substr(value, 1, red - 1)
          right = substr(value, red)
          connector = ""
          if (match(left, /(或者|或)[[:space:]]*$/)) {
            connector = substr(left, RSTART)
            left = substr(left, 1, RSTART - 1)
          }
          return segment(left, 0) connector segment(right, 31)
        }
        if (red && green && red < green && match(value, /或[[:space:]]*(直接|仅|只需|只|按下|按)?(回车|回車)/)) {
          splitAt = RSTART
          return segment(substr(value, 1, splitAt - 1), 31) "或" segment(substr(value, splitAt + length("或")), 0)
        }
        if (red) {
          kind = 31
          start = red
        } else if (green) {
          kind = 32
          start = green
        }
      }
      if (!kind || !color) return value
      prefix = substr(value, 1, start - 1)
      body = substr(value, start)
      return prefix esc "[1;" kind "m" body esc "[0m"
    }
    function render(value, output, part, boundary, inherited, kind, consumed, depth, original) {
      original = value
      gsub(esc "\\[[0-9;]*m", "", value)
      if (color && keep && !greenPosition(value) && value !~ /(任意|任何|非空|其它输入|其他输入|[Tt]ype (anything|any[^ ]*)|[Pp]ress any key)/) return original
      output = ""
      inherited = 0
      depth = 0
      while (match(value, /[；;\/|，,、？?：:=＝（）()\[\]【】]/)) {
        part = substr(value, 1, RSTART - 1)
        boundary = substr(value, RSTART, RLENGTH)
        consumed = RSTART + RLENGTH
        output = output segment(part, inherited) boundary
        if (boundary ~ /[（(\[【]/) {
          depth++
          if (part ~ /(任意|任何|非空|其它输入|其他输入|[Tt]ype (anything|any[^ ]*)|[Pp]ress any key)/) inherited = 31
          else if (greenPosition(part)) inherited = 32
        } else if (boundary ~ /[）)\]】]/) {
          if (depth) depth--
        } else if (boundary ~ /[：:=＝]/) {
          if (!inherited) {
            if (part ~ /(任意|任何|非空|其它输入|其他输入)/) inherited = 31
            else if (greenPosition(part)) inherited = 32
          }
        } else if (!depth) inherited = 0
        value = substr(value, consumed)
      }
      return output segment(value, inherited)
    }
    BEGIN { esc = sprintf("%c", 27); first = 1 }
    {
      if (lines == 2) {
        if (!first) printf "%s\n", render(pending)
        pending = $0
        first = 0
        next
      }
      if (!lines && !first) printf "\n"
      printf "%s", render($0)
      if (lines) printf "\n"
      first = 0
    }
    END {
      if (lines == 2 && !first) {
        sub(sprintf("%c", 1) "$", "", pending)
        printf "%s", render(pending)
      }
    }
  '
}
# read 的命令替换会使 stdout 成为管道，按输入与提示所在 stderr 判断终端。
jobs_prompt_render() {
  local jobs_prompt_color=0
  if [ -t 0 ] && [ -t 2 ] && jobs_prompt_color_ready; then jobs_prompt_color=1; fi
  printf "%s" "$1" | jobs_prompt_format "$jobs_prompt_color" 0
}
# 仅放在显示链末端；tee 在此函数之前接收纯文本，不把 ANSI 写入日志。
jobs_prompt_stream() {
  local jobs_prompt_color=0
  if [ -t 1 ] && jobs_prompt_color_ready; then jobs_prompt_color=1; fi
  jobs_prompt_format "$jobs_prompt_color" 1 1
}
# 显示管道保留原末尾换行；只删除本轮追加的最后一个结束标记。
jobs_prompt_filter() {
  local jobs_prompt_color=0
  if [ -t 1 ] && jobs_prompt_color_ready; then jobs_prompt_color=1; fi
  { /bin/cat; printf '\001'; } | jobs_prompt_format "$jobs_prompt_color" 2 1
}
# 仅包装原 printf/echo/print 展示，原参数、尾换行与显示命令退出码保持不变。
jobs_prompt_output() {
  local jobs_prompt_status=0 jobs_prompt_stderr=0 jobs_prompt_arg="" jobs_prompt_previous=""
  if [ "${1:-}" = print ]; then
    for jobs_prompt_arg in "$@"; do
      case "$jobs_prompt_arg" in -?*u2*|-u2) jobs_prompt_stderr=1 ;; esac
      if [ "$jobs_prompt_previous" = -u ] && [ "$jobs_prompt_arg" = 2 ]; then jobs_prompt_stderr=1; fi
      jobs_prompt_previous="$jobs_prompt_arg"
      [ "$jobs_prompt_arg" != -- ] || break
    done
  fi
  if [ -n "${ZSH_VERSION:-}" ]; then
    if [ "$jobs_prompt_stderr" = 1 ]; then
      "$@" 2>&1 | jobs_prompt_filter >&2
      jobs_prompt_status=$(( ${pipestatus[1]} != 0 ? ${pipestatus[1]} : ${pipestatus[2]} ))
    else
      "$@" | jobs_prompt_filter
      jobs_prompt_status=$(( ${pipestatus[1]} != 0 ? ${pipestatus[1]} : ${pipestatus[2]} ))
    fi
  elif [ -n "${BASH_VERSION:-}" ]; then
    "$@" | jobs_prompt_filter
    jobs_prompt_status=$(( ${PIPESTATUS[0]} != 0 ? ${PIPESTATUS[0]} : ${PIPESTATUS[1]} ))
  else
    "$@" | jobs_prompt_filter
    jobs_prompt_status=$?
  fi
  return "$jobs_prompt_status"
}
# 仅替换日志 primitive 的 tee：磁盘同步追加纯文，终端保留非选项原色。
jobs_prompt_tee() {
  local jobs_prompt_log="$1" jobs_prompt_line="" jobs_prompt_newline=0
  while :; do
    jobs_prompt_line=""
    if IFS= read -r jobs_prompt_line; then jobs_prompt_newline=1; else jobs_prompt_newline=0; [ -n "$jobs_prompt_line" ] || break; fi
    if [ "$jobs_prompt_newline" = 1 ]; then
      { printf '%s\n' "$jobs_prompt_line"; printf '\001'; } | jobs_prompt_format 0 2 >> "$jobs_prompt_log" || return $?
      printf '%s\n' "$jobs_prompt_line" | jobs_prompt_filter || return $?
    else
      { printf '%s' "$jobs_prompt_line"; printf '\001'; } | jobs_prompt_format 0 2 >> "$jobs_prompt_log" || return $?
      printf '%s' "$jobs_prompt_line" | jobs_prompt_filter || return $?
    fi
  done
}
# JOBS_INPUT_CHOICE_STYLE_END

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
log()            { if [[ -n "${LOG_FILE:-}" ]]; then echo -e "$1" | jobs_prompt_tee "$LOG_FILE"; else echo -e "$1"; fi }
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
    jobs_prompt_output note_echo "已指定 --yes，跳过回车确认。"
    return 0
  fi
  if [[ ! -t 0 ]]; then
    error_echo "当前没有可交互标准输入，不能确认；请在终端重新运行，或显式加 --yes。"
    return 1
  fi
  echo ""
  read -r "?$(jobs_prompt_render "👉 已了解脚本用途与影响，按回车继续；按 Ctrl+C 取消：")" answer
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
