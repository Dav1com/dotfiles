# Terminal defaults, so Helix and other TUIs render full color. Needed here too
# because fish may be started directly (e.g. VS Code's terminal profile), not
# via bash; keep in sync with shell/env.sh.
if not set -q TERM; or test "$TERM" = dumb
    set -gx TERM xterm-256color
end
set -q COLORTERM; or set -gx COLORTERM truecolor
