#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# HamadaOS — Startup Sound
# ═══════════════════════════════════════════════════════════════════════════════
# Plays a startup chime after login. Drop a startup.ogg in ~/.config/sounds/.
# Bound via exec-once in userprefs.conf.
# ═══════════════════════════════════════════════════════════════════════════════
sleep 1.5
SOUND_FILE="$HOME/.config/sounds/startup.ogg"
if [[ -f "$SOUND_FILE" ]]; then
    # pw-play ships with PipeWire (always present); mpv as fallback.
    if command -v pw-play &>/dev/null; then
        pw-play --volume=0.6 "$SOUND_FILE" &
    elif command -v mpv &>/dev/null; then
        mpv --no-video --volume=60 "$SOUND_FILE" &
    fi
elif command -v canberra-gtk-play &>/dev/null; then
    canberra-gtk-play -i desktop-login &
fi
