# Sourced from ~/.bashrc and ~/.zshrc: replace interactive shells with fish.
#
# Skipped when:
#   - the shell isn't attached to a terminal or runs a command (`bash -ic ...`),
#     so tools that probe the environment (e.g. VS Code) keep working
#   - the parent process is fish, so running `bash` from fish still gives bash
#   - NO_FISH is set, as an escape hatch: `NO_FISH=1 bash`
case $- in
*i*)
	if [ -t 0 ] && [ -t 1 ] &&
		[ -z "${BASH_EXECUTION_STRING:-}${ZSH_EXECUTION_STRING:-}" ] &&
		[ -z "${NO_FISH:-}" ] &&
		command -v fish >/dev/null 2>&1 &&
		[ "$(cat /proc/$PPID/comm 2>/dev/null)" != fish ]; then
		# `bash -l` doesn't prefix $0 with "-", so ask the shell itself too.
		if case $0 in -*) true ;; *) false ;; esac ||
			{ [ -n "${BASH_VERSION:-}" ] && shopt -q login_shell; } ||
			{ [ -n "${ZSH_VERSION:-}" ] && [[ -o login ]]; }; then
			exec fish --login
		fi
		exec fish
	fi
	;;
esac
