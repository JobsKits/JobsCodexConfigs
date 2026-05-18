# Snapshot file
# Unset all aliases to avoid conflicts with functions
unalias -a 2>/dev/null || true
# Functions
_jenv_export_hook () {
	export JAVA_HOME="$(jenv javahome 2>/dev/null)" 
	export JENV_FORCEJAVAHOME=true 
	if [ -e "$JAVA_HOME/bin/javac" ]
	then
		export JDK_HOME="$JAVA_HOME" 
		export JENV_FORCEJDKHOME=true 
	fi
}
_jobs_resolve_scripts_command () {
	emulate -L zsh
	local command_name="$1" 
	local env_home="${JOBS_MAC_ENV_HOME:-$HOME/.JobsMacEnv}" 
	local scripts_dir="$env_home/Scripts" 
	local script_file="${command_name}.command" 
	local candidates=("$scripts_dir/$script_file/$script_file" "$scripts_dir/$script_file") 
	local candidate="" 
	for candidate in "${candidates[@]}"
	do
		if [[ -x "$candidate" ]]
		then
			print -r -- "$candidate"
			return 0
		fi
	done
	return 1
}
_jobs_restore_stateful_wrapper () {
	emulate -L zsh
	local command_name="$1" 
	local main_function="$2" 
	eval "${command_name}() { _jobs_source_and_run_scripts_command ${command_name} ${main_function} \"\$@\"; }"
}
_jobs_run_scripts_command () {
	emulate -L zsh
	local command_name="$1" 
	shift
	local script="" 
	if ! script="$(_jobs_resolve_scripts_command "$command_name")" 
	then
		echo "$command_name: 主脚本不存在或不可执行" >&2
		echo "👉 请重新执行 JobsMacEnv 安装脚本" >&2
		return 127
	fi
	"$script" "$@"
}
_jobs_source_and_run_scripts_command () {
	emulate -L zsh
	local command_name="$1" 
	local main_function="$2" 
	shift 2
	local script="" 
	if ! script="$(_jobs_resolve_scripts_command "$command_name")" 
	then
		echo "$command_name: 主脚本不存在或不可执行" >&2
		echo "👉 请重新执行 JobsMacEnv 安装脚本" >&2
		return 127
	fi
	local previous_source_mode="${JOBS_MAC_ENV_SOURCE_MODE:-}" 
	JOBS_MAC_ENV_SOURCE_MODE="1" 
	source "$script" || {
		if [[ -n "$previous_source_mode" ]]
		then
			JOBS_MAC_ENV_SOURCE_MODE="$previous_source_mode" 
		else
			unset JOBS_MAC_ENV_SOURCE_MODE
		fi
		return 1
	}
	if [[ -n "$previous_source_mode" ]]
	then
		JOBS_MAC_ENV_SOURCE_MODE="$previous_source_mode" 
	else
		unset JOBS_MAC_ENV_SOURCE_MODE
	fi
	if ! typeset -f "$main_function" > /dev/null 2>&1
	then
		echo "$command_name: 入口函数不存在：$main_function" >&2
		_jobs_restore_stateful_wrapper "$command_name" "$main_function"
		return 127
	fi
	"$main_function" "$@"
	local status=$? 
	_jobs_restore_stateful_wrapper "$command_name" "$main_function"
	return $status
}
a () {
	_jobs_run_scripts_command a "$@"
}
apk () {
	_jobs_source_and_run_scripts_command apk jobs_apk_main "$@"
}
b () {
	_jobs_run_scripts_command b "$@"
}
buildCheck () {
	_jobs_source_and_run_scripts_command buildCheck jobs_buildCheck_main "$@"
}
c () {
	_jobs_source_and_run_scripts_command c jobs_c_main "$@"
}
check () {
	_jobs_source_and_run_scripts_command check jobs_check_main "$@"
}
check1 () {
	_jobs_run_scripts_command check1 "$@"
}
clean () {
	_jobs_run_scripts_command clean "$@"
}
config () {
	_jobs_run_scripts_command config "$@"
}
cor () {
	_jobs_run_scripts_command cor "$@"
}
d () {
	_jobs_source_and_run_scripts_command d jobs_d_main "$@"
}
decode () {
	_jobs_run_scripts_command decode "$@"
}
download () {
	_jobs_run_scripts_command download "$@"
}
fixfvm () {
	_jobs_run_scripts_command fixfvm "$@"
}
flat () {
	_jobs_run_scripts_command flat "$@"
}
gif () {
	_jobs_run_scripts_command gif "$@"
}
i () {
	_jobs_run_scripts_command i "$@"
}
install () {
	_jobs_run_scripts_command install "$@"
}
install_hook () {
	emulate -LR zsh
	typeset -ag precmd_functions
	if [[ -z $precmd_functions[(r)_jenv_export_hook] ]]
	then
		precmd_functions+=_jenv_export_hook 
	fi
}
ipa () {
	_jobs_source_and_run_scripts_command ipa jobs_ipa_main "$@"
}
jenv () {
	type typeset &> /dev/null && typeset command
	command="$1" 
	if [ "$#" -gt 0 ]
	then
		shift
	fi
	case "$command" in
		(enable-plugin | rehash | shell | shell-options) eval "`jenv \"sh-$command\" \"$@\"`" ;;
		(*) command jenv "$command" "$@" ;;
	esac
}
jobs_brew_prefix () {
	if command -v brew > /dev/null 2>&1
	then
		brew --prefix
	else
		echo ""
	fi
}
jobs_command_exists () {
	command -v "$1" > /dev/null 2>&1
}
jobs_detect_arch () {
	uname -m
}
jobs_log () {
	echo "[jobs-env] $1"
}
jobs_path_add () {
	local dir="$1" 
	[[ -n "$dir" ]] || return 0
	[[ -d "$dir" ]] || return 0
	jobs_path_has "$dir" || PATH="$dir:$PATH" 
}
jobs_path_append () {
	local dir="$1" 
	[[ -n "$dir" ]] || return 0
	[[ -d "$dir" ]] || return 0
	jobs_path_has "$dir" || PATH="$PATH:$dir" 
}
jobs_path_has () {
	local dir="$1" 
	case ":$PATH:" in
		(*":$dir:"*) return 0 ;;
		(*) return 1 ;;
	esac
}
jobs_resolve_java_home () {
	local version="$1" 
	local java_home="" 
	if [[ -x /usr/libexec/java_home ]]
	then
		java_home=$(/usr/libexec/java_home -v "$version" 2>/dev/null || true) 
	fi
	if [[ -n "$java_home" && -d "$java_home" ]]
	then
		printf "%s" "$java_home"
		return 0
	fi
	local candidates=("/Library/Java/JavaVirtualMachines/temurin-${version}.jdk/Contents/Home" "/Library/Java/JavaVirtualMachines/zulu-${version}.jdk/Contents/Home" "/Library/Java/JavaVirtualMachines/openjdk-${version}.jdk/Contents/Home" "/opt/homebrew/opt/openjdk@${version}/libexec/openjdk.jdk/Contents/Home" "/usr/local/opt/openjdk@${version}/libexec/openjdk.jdk/Contents/Home") 
	local item
	for item in "${candidates[@]}"
	do
		if [[ -d "$item" ]]
		then
			printf "%s" "$item"
			return 0
		fi
	done
	return 1
}
jobs_setup_android () {
	local sdk_dir="$1" 
	[[ -d "$sdk_dir" ]] || return 0
	export ANDROID_SDK_ROOT="$sdk_dir" 
	export ANDROID_HOME="$sdk_dir" 
	jobs_path_add "$sdk_dir/platform-tools"
	jobs_path_add "$sdk_dir/cmdline-tools/latest/bin"
	jobs_path_add "$sdk_dir/emulator"
	jobs_path_add "$sdk_dir/tools"
	jobs_path_add "$sdk_dir/tools/bin"
}
jobs_setup_flutter () {
	local use_fvm="$1" 
	local candidates_csv="$2" 
	if [[ "$use_fvm" == "true" ]]
	then
		jobs_path_add "$HOME/.pub-cache/bin"
	fi
	local old_ifs="$IFS" 
	IFS=',' 
	local item
	for item in $candidates_csv
	do
		item="${item/#\$HOME/$HOME}" 
		if [[ -d "$item" ]]
		then
			jobs_path_add "$item"
			break
		fi
	done
	IFS="$old_ifs" 
}
jobs_setup_go () {
	local gopath="$1" 
	export GOPATH="$gopath" 
	jobs_path_add "$GOPATH/bin"
}
jobs_setup_java () {
	local version="$1" 
	local java_home="" 
	java_home="$(jobs_resolve_java_home "$version" 2>/dev/null || true)" 
	if [[ -n "$java_home" && -d "$java_home" ]]
	then
		export JAVA_HOME="$java_home" 
		jobs_path_add "$JAVA_HOME/bin"
	fi
}
jobs_setup_node () {
	local enable_corepack="$1" 
	local nvm_dir="$2" 
	export NVM_DIR="$nvm_dir" 
	if [[ -s "$NVM_DIR/nvm.sh" ]]
	then
		source "$NVM_DIR/nvm.sh"
	fi
	if [[ "$enable_corepack" == "true" ]] && jobs_command_exists corepack
	then
		true
	fi
}
jobs_setup_pyenv () {
	local pyenv_root="$1" 
	if [[ -d "$pyenv_root" ]]
	then
		export PYENV_ROOT="$pyenv_root" 
		jobs_path_add "$PYENV_ROOT/bin"
		if jobs_command_exists pyenv
		then
			eval "$(pyenv init - zsh)"
		fi
	fi
}
jobs_setup_rbenv () {
	local rbenv_root="$1" 
	if [[ -d "$rbenv_root" ]]
	then
		export RBENV_ROOT="$rbenv_root" 
		jobs_path_add "$RBENV_ROOT/bin"
		if jobs_command_exists rbenv
		then
			eval "$(rbenv init - zsh)"
		fi
	fi
}
jobs_setup_rust () {
	local cargo_home="$1" 
	export CARGO_HOME="$cargo_home" 
	jobs_path_add "$CARGO_HOME/bin"
}
jobs_source_if_exists () {
	local file="$1" 
	[[ -f "$file" ]] && source "$file"
}
list () {
	_jobs_run_scripts_command list "$@"
}
m5c () {
	_jobs_run_scripts_command m5c "$@"
}
pods () {
	_jobs_run_scripts_command pods "$@"
}
rb () {
	_jobs_source_and_run_scripts_command rb jobs_rb_main "$@"
}
rbenv () {
	local command
	command="${1:-}" 
	if [ "$#" -gt 0 ]
	then
		shift
	fi
	case "$command" in
		(rehash | shell) eval "$(rbenv "sh-$command" "$@")" ;;
		(*) command rbenv "$command" "$@" ;;
	esac
}
save () {
	_jobs_source_and_run_scripts_command save jobs_save_main "$@"
}
shell () {
	_jobs_run_scripts_command shell "$@"
}
simios () {
	_jobs_run_scripts_command simios "$@"
}
trs () {
	_jobs_run_scripts_command trs "$@"
}
ts () {
	_jobs_run_scripts_command ts "$@"
}
update () {
	_jobs_run_scripts_command update "$@"
}
x () {
	_jobs_run_scripts_command x "$@"
}
zz () {
	_jobs_source_and_run_scripts_command zz jobs_zz_main "$@"
}

# setopts 2
setopt nohashdirs
setopt login

# aliases 10
alias ga='git add .'
alias gc='git commit'
alias gl='git pull'
alias gp='git push'
alias gs='git status'
alias l='ls -CF'
alias la='ls -A'
alias ll='ls -alF'
alias run-help=man
alias which-command=whence

# exports 46
export ANDROID_HOME=/Users/jobs/Library/Android/sdk
export ANDROID_SDK_ROOT=/Users/jobs/Library/Android/sdk
export CARGO_HOME=/Users/jobs/.cargo
export CODEX_INTERNAL_ORIGINATOR_OVERRIDE='Codex Desktop'
export CODEX_SHELL=1
export COMMAND_MODE=unix2003
export DISABLE_AUTO_UPDATE=true
export GOPATH=/Users/jobs/go
export HOME=/Users/jobs
export HOMEBREW_CELLAR=/opt/homebrew/Cellar
export HOMEBREW_PREFIX=/opt/homebrew
export HOMEBREW_REPOSITORY=/opt/homebrew
export INFOPATH=/opt/homebrew/share/info:/opt/homebrew/share/info:/opt/homebrew/share/info:/opt/homebrew/share/info:/opt/homebrew/share/info:
export JAVA_HOME=''
export JENV_FORCEJAVAHOME=true
export JENV_LOADED=1
export JENV_SHELL=zsh
export JOBS_MAC_ENV_HOME=/Users/jobs/.JobsMacEnv
export JOBS_USER_MOUNTS_DIR=/Users/jobs/.JobsMacEnv/zsh/custom
export LANG=C.UTF-8
export LESS=-R
export LOGNAME=jobs
export LOG_FORMAT=json
export LSCOLORS=Gxfxcxdxbxegedabagacad
export LS_COLORS='di=1;36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'
export LaunchInstanceID=A55CFA67-F960-409D-B960-DF77404C8BA8
export MallocNanoZone=0
export NVM_DIR=/Users/jobs/.nvm
export OSLogRateLimit=64
export PAGER=less
export PNPM_HOME=/Users/jobs/Library/pnpm
export RBENV_ROOT=/Users/jobs/.rbenv
export RBENV_SHELL=zsh
export RUST_LOG=warn
export SECURITYSESSIONID=186b0
export SHELL=/bin/zsh
export SSH_AUTH_SOCK=/var/run/com.apple.launchd.mCp3PoZVg1/Listeners
export TMPDIR=/var/folders/r6/sb0vlrj92qg__pr4zcc4nznm0000gn/T/
export USER=jobs
export XPC_FLAGS=0x0
export XPC_SERVICE_NAME=0
export ZSH=/Users/jobs/.oh-my-zsh
export ZSH_TMUX_AUTOSTART=false
export ZSH_TMUX_AUTOSTARTED=true
export __CFBundleIdentifier=com.openai.codex
export __CF_USER_TEXT_ENCODING=0x1F5:0x19:0x34
