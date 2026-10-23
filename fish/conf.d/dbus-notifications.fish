# Fall back to the host's filtered D-Bus proxy (notifications only) when the
# devcontainer mounts it but doesn't set DBUS_SESSION_BUS_ADDRESS, so Claude's
# Notification hook still reaches the desktop.
if not set -q DBUS_SESSION_BUS_ADDRESS
    for bus in /run/user/*/devcontainer-dbus/bus
        if test -S $bus
            set -gx DBUS_SESSION_BUS_ADDRESS unix:path=$bus
            break
        end
    end
end
