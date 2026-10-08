# Never trust the ready marker when one of the live workspace SVGs is
# missing, invalid, or still rendered white. This catches stale files left by
# older navbar-renderer revisions.
# Gradient icons encode visible paint in stop-color values. Treat a gradient
# as unhealthy only when every stop is white; white-to-color gradients are valid.
NAVBAR_ASSETS_HEALTHY=1
for slot in home code web comms studio music; do
    generated="$STATE_DIR/navbar-icons/$slot.svg"
    GRADIENT_ALL_WHITE=0

    if [ -s "$generated" ] && grep -q '<svg' "$generated"; then
        if grep -q 'stop-color=' "$generated"; then
            GRADIENT_ALL_WHITE=1
            stop_file="$(mktemp)"
            grep -Eo 'stop-color="[^"]+"' "$generated" \
                | sed 's/^stop-color="//; s/"$//' > "$stop_file" || true
            while IFS= read -r value; do
                case "$(printf '%s' "$value" | tr '[:lower:]' '[:upper:]')" in
                    WHITE|#FFFFFF|#FFFFFFFF) ;;
                    *) GRADIENT_ALL_WHITE=0; break ;;
                esac
            done < "$stop_file"
            rm -f "$stop_file"
        fi
    fi

    if [ ! -s "$generated" ] || ! grep -q '<svg' "$generated" \
       || grep -Eiq 'stroke="(white|#fff([0-9a-f]{2})?|#ffffff([0-9a-f]{2})?)"' "$generated" \
       || [ "$GRADIENT_ALL_WHITE" -eq 1 ]; then
        NAVBAR_ASSETS_HEALTHY=0
        break
    fi
done

if [ "$NAVBAR_SYNC_SHA" != "$PREVIOUS_NAVBAR_SYNC_SHA" ] \
   || [ ! -f "$STATE_DIR/navbar-icons/ready" ] \
   || [ "$ICON_SYNCED" -eq 1 ] \
   || [ "$NAVBAR_ASSETS_HEALTHY" -ne 1 ]; then
    echo "==> Generating A16EEN navbar icons"
    if bash "$ROOT_DIR/scripts/a16een-navbar" apply; then
        printf '%s\n' "$NAVBAR_SYNC_SHA" > "$NAVBAR_SYNC_MARKER"
    else
        echo "WARNING: navbar icon generation failed; the navbar will use bundled fallbacks." >&2
    fi
else
    echo "==> A16EEN navbar icons already generated; skipping rebuild."
fi

# If A16EEN is already running, restart only its Quickshell process after
# deployment. This is especially important when a revision adds or removes QML
# component files, which a live hot-reload may not register reliably.
if [ "${XDG_CURRENT_DESKTOP:-}" = "A16EEN" ]; then
    CONFIG_SHELL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/a16een/quickshell/a16een"
    RESTARTED_SHELL=0

    for cmdline in /proc/[0-9]*/cmdline; do
        [ -r "$cmdline" ] || continue
        PID="${cmdline#/proc/}"
        PID="${PID%/cmdline}"
        case "$PID" in
            ''|*[!0-9]*) continue ;;
        esac

        ARGS="$(tr '\0' ' ' < "$cmdline" 2>/dev/null || true)"
        case "$ARGS" in
            *"qs -c $CONFIG_SHELL_DIR"*)
                if kill -TERM "$PID" 2>/dev/null; then
                    RESTARTED_SHELL=1
                fi
                ;;
        esac
    done

    if [ "$RESTARTED_SHELL" -eq 1 ]; then
        echo "==> Restarted the A16EEN Quickshell shell."
    fi

    # If the supervisor itself exited after repeated QML failures, recover it
    # without requiring the user to leave the desktop session.
    if ! pgrep -f '[a]16een-shell' >/dev/null 2>&1; then
        nohup /usr/local/bin/a16een-shell >/dev/null 2>&1 &
        echo "==> Started the A16EEN shell supervisor."
    fi
fi

echo
echo "╭──────────────────────────────────────────────╮"
echo "│           A16EEN installation complete       │"
echo "╰──────────────────────────────────────────────╯"
echo "Run 'a16een-update' whenever you want to check for updates."
echo "Built-in wallpapers: $QS_DIR/assets/wallpapers"
echo "Personal wallpapers: $USER_WALLPAPER_DIR"
echo "Personal animated wallpapers: $USER_WALLPAPER_DIR/animated"
