#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# HamadaOS — Screen OCR (Text Extractor)
# ═══════════════════════════════════════════════════════════════════════════════
# PowerToys Text Extractor equivalent. Select a region of the screen,
# extract text via tesseract OCR, and copy to clipboard.
#
# Supports English + Arabic simultaneously: tesseract -l eng+ara
#
# Bound to: Super+Shift+T  (keybindings.conf)
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

TMPFILE="$(mktemp /tmp/hamadaos-ocr-XXXXXX.png)"
trap 'rm -f "$TMPFILE"' EXIT

# ── Step 1: Freeze screen while selecting (optional — degrades gracefully) ────
# wayfreeze freezes the current frame so the user can select without visual
# changes from animations or video playback.
FREEZE_PID=""
if command -v wayfreeze &>/dev/null; then
    echo "[OCR] Freezing screen..."
    wayfreeze &
    FREEZE_PID=$!
    sleep 0.2   # give wayfreeze time to grab the frame
fi

# ── Step 2: Select area with slurp ─────────────────────────────────────────────
echo "[OCR] Select area to OCR..."
GEOMETRY="$(slurp -d 2>/dev/null)" || {
    [[ -n "$FREEZE_PID" ]] && kill "$FREEZE_PID" 2>/dev/null || true
    echo "[OCR] Selection cancelled."
    exit 0
}

# ── Step 3: Capture the selected region ────────────────────────────────────────
grim -g "$GEOMETRY" "$TMPFILE"

# ── Step 4: Kill wayfreeze (screen unfreezes) ─────────────────────────────────
[[ -n "$FREEZE_PID" ]] && kill "$FREEZE_PID" 2>/dev/null || true

# ── Step 5: Extract text with tesseract (English + Arabic) ─────────────────────
echo "[OCR] Running tesseract (eng+ara)..."
TEXT="$(tesseract "$TMPFILE" stdout -l eng+ara 2>/dev/null)" || {
    echo "[OCR] tesseract failed. Is it installed? sudo pacman -S tesseract tesseract-data-eng tesseract-data-ara"
    exit 1
}

# ── Step 6: Copy to clipboard ──────────────────────────────────────────────────
echo -n "$TEXT" | wl-copy
echo "[OCR] Copied to clipboard."

# ── Step 7: Show notification with first 120 characters ────────────────────────
PREVIEW="$(echo "$TEXT" | tr '\n' ' ' | head -c 120)"
if [[ ${#TEXT} -gt 120 ]]; then
    PREVIEW="${PREVIEW}…"
fi

if command -v notify-send &>/dev/null; then
    notify-send \
        -a "HamadaOS" \
        -i "edit-copy" \
        -t 4000 \
        "OCR Complete" \
        "$PREVIEW"
fi
