# Terminal defaults, so Helix and other TUIs render full color. TERM is only
# filled in when missing (e.g. `podman exec` without a terminal type), since
# terminals like tmux set their own; keep in sync with fish/conf.d/env.fish.
case "${TERM:-dumb}" in dumb) export TERM=xterm-256color ;; esac
export COLORTERM="${COLORTERM:-truecolor}"
