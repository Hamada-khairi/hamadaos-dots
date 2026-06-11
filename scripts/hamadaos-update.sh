#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# HamadaOS — Update Manager
# ═══════════════════════════════════════════════════════════════════════════════
#   hamadaos-update.sh --check    JSON counts: CachyOS/Arch repos, AUR,
#                                 hamadaos-dots git, HyDE git
#   hamadaos-update.sh --apply    update EVERYTHING in order, then re-link
#                                 dots and re-run the doctor
#
# The Settings → Health page consumes --check and launches --apply in a
# terminal (updates want a visible log, not a silent background job).
# ═══════════════════════════════════════════════════════════════════════════════

set -uo pipefail

AUR_HELPER="$(command -v yay || command -v paru || true)"
REPO_DIR="$(dirname "$(readlink -f "$HOME/.config/hypr/userprefs.conf" 2>/dev/null)" 2>/dev/null)"
REPO_DIR="${REPO_DIR%/config/hypr}"
HYDE_DIR="$HOME/HyDE"

git_behind() {  # count of commits behind origin, or 0
    local dir="$1"
    [[ -d "$dir/.git" ]] || { echo 0; return; }
    git -C "$dir" fetch -q 2>/dev/null || { echo 0; return; }
    git -C "$dir" rev-list --count "HEAD..@{upstream}" 2>/dev/null || echo 0
}

case "${1:-}" in
--check)
    REPO_N=0; AUR_N=0
    if command -v checkupdates >/dev/null 2>&1; then
        REPO_N="$(checkupdates 2>/dev/null | wc -l)"
    fi
    if [[ -n "$AUR_HELPER" ]]; then
        AUR_N="$("$AUR_HELPER" -Qua 2>/dev/null | wc -l)"
    fi
    DOTS_N="$(git_behind "$REPO_DIR")"
    HYDE_N="$(git_behind "$HYDE_DIR")"
    printf '{"repo":%d,"aur":%d,"dots":%d,"hyde":%d,"total":%d}\n' \
        "$REPO_N" "$AUR_N" "$DOTS_N" "$HYDE_N" \
        "$(( REPO_N + AUR_N + DOTS_N + HYDE_N ))"
    ;;

--apply)
    echo "═══ HamadaOS Update ═══════════════════════════════════"

    # ── PREVIEW: show exactly what will change before touching anything ──────
    echo ""
    echo "── What this update will touch"
    if command -v checkupdates >/dev/null 2>&1; then
        N="$(checkupdates 2>/dev/null | wc -l)"
        echo "  System packages: $N"
        checkupdates 2>/dev/null | head -15 | sed 's/^/      /'
        [[ "$N" -gt 15 ]] && echo "      … and $((N - 15)) more"
    fi
    if [[ -n "$AUR_HELPER" ]]; then
        echo "  AUR packages: $("$AUR_HELPER" -Qua 2>/dev/null | wc -l)"
        "$AUR_HELPER" -Qua 2>/dev/null | head -8 | sed 's/^/      /'
    fi
    for repo_pair in "HyDE:$HYDE_DIR" "hamadaos-dots:$REPO_DIR"; do
        rname="${repo_pair%%:*}"; rdir="${repo_pair#*:}"
        n="$(git_behind "$rdir")"
        if [[ "$n" -gt 0 ]]; then
            echo "  $rname: $n new commit(s)"
            git -C "$rdir" log --oneline "HEAD..@{upstream}" 2>/dev/null | head -5 | sed 's/^/      /'
        fi
    done
    echo ""
    echo "  Safety: a Btrfs snapshot (snap-pac) + a settings backup are taken"
    echo "  first. Roll back any time: Safe Mode → option 6."
    echo ""
    read -rp "Proceed? [y/N] " yn
    [[ "$yn" =~ ^[Yy]$ ]] || { echo "Cancelled — nothing was changed."; exit 0; }

    # ── Pre-update safety net ─────────────────────────────────────────────────
    "$HOME/.config/hypr/scripts/hamadaos-backup.sh" auto || true
    sudo snapper -c root create -d "hamadaos pre-update" 2>/dev/null \
        && echo "  ✓ system snapshot created" || true

    echo ""
    echo "── [1/4] System packages (CachyOS/Arch + AUR)"
    if [[ -n "$AUR_HELPER" ]]; then
        "$AUR_HELPER" -Syu --noconfirm || echo "!! package update had errors — see above"
    else
        sudo pacman -Syu --noconfirm || echo "!! package update had errors"
    fi

    echo ""
    echo "── [2/4] HyDE"
    if [[ -d "$HYDE_DIR/.git" ]]; then
        git -C "$HYDE_DIR" pull --ff-only && {
            if [[ -x "$HYDE_DIR/Scripts/install.sh" ]]; then
                echo "   HyDE updated — running its restore (configs preserved)…"
                (cd "$HYDE_DIR/Scripts" && ./install.sh -r) || echo "!! HyDE restore reported errors"
            fi
        }
    else
        echo "   HyDE not managed via git here — skipped"
    fi

    echo ""
    echo "── [3/4] hamadaos-dots"
    if [[ -d "$REPO_DIR/.git" ]]; then
        git -C "$REPO_DIR" pull --ff-only \
            && HAMADAOS_LINKS_ONLY=1 bash "$REPO_DIR/install.sh"
    else
        echo "   dots not a git checkout — skipped"
    fi

    echo ""
    echo "── [4/4] Health check"
    "$HOME/.config/hypr/scripts/hamadaos-doctor.sh" --fix || true

    echo ""
    echo "═══ Update complete. Reboot recommended after kernel updates. ═══"
    read -rp "Press Enter to close…"
    ;;

*)
    echo "Usage: hamadaos-update.sh <--check|--apply>"
    exit 1
    ;;
esac
