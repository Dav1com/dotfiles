#!/bin/sh
# Claude Code Notification hook: forward the message to the freedesktop
# notification service (GNOME tray) over the session D-Bus.
# Works on the host and in the dev container (which mounts the host bus).
[ -n "$DBUS_SESSION_BUS_ADDRESS" ] || exit 0
command -v gdbus >/dev/null 2>&1 || exit 0

msg=$(jq -r '.message // "Claude Code needs your attention"' 2>/dev/null)
[ -n "$msg" ] || msg="Claude Code needs your attention"
# Escape for a GVariant string literal
msg=$(printf '%s' "$msg" | sed 's/\\/\\\\/g; s/"/\\"/g')

gdbus call --session \
  --dest org.freedesktop.Notifications \
  --object-path /org/freedesktop/Notifications \
  --method org.freedesktop.Notifications.Notify \
  "Claude Code" 0 "" "Claude Code" "\"$msg\"" '[]' '{}' 8000 >/dev/null 2>&1
exit 0
