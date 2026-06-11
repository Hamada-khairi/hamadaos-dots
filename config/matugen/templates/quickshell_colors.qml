// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Quickshell Colors (matugen template)
// ═══════════════════════════════════════════════════════════════════════════════
// This file is processed by matugen. {{colors.X.default}} placeholders are
// replaced with hex colors extracted from the current wallpaper.
// Output goes to: ~/.config/quickshell/GeneratedColors.qml
//
// Theme.qml imports GeneratedColors as a singleton. All QML components
// bind to Theme, which reads from here.
//
// Reference:
//   end-4/dots-hyprland — colors.json matugen template
//   HamadaOS build plan §4 — GeneratedColors specification
// ═══════════════════════════════════════════════════════════════════════════════

pragma Singleton
import QtQuick

QtObject {
    // ── Primary palette ───────────────────────────────────────────────────
    property color primary:        "{{colors.primary.default.hex}}"
    property color onPrimary:      "{{colors.on_primary.default.hex}}"

    // ── Surface hierarchy ──────────────────────────────────────────────────
    property color surface:        "{{colors.surface.default.hex}}"
    property color surfaceVariant: "{{colors.surface_variant.default.hex}}"
    property color onSurface:      "{{colors.on_surface.default.hex}}"
    property color onSurfaceVar:   "{{colors.on_surface_variant.default.hex}}"

    // ── Outline ────────────────────────────────────────────────────────────
    property color outline:        "{{colors.outline.default.hex}}"

    // ── Error ──────────────────────────────────────────────────────────────
    property color error:          "{{colors.error.default.hex}}"

    // ── Extended palette ──────────────────────────────────────────────────
    property color secondary:      "{{colors.secondary.default.hex}}"
    property color tertiary:       "{{colors.tertiary.default.hex}}"
    property color primaryContainer:   "{{colors.primary_container.default.hex}}"
    property color secondaryContainer: "{{colors.secondary_container.default.hex}}"
    property color surfaceBright:  "{{colors.surface_bright.default.hex}}"
    property color surfaceDim:     "{{colors.surface_dim.default.hex}}"
    property color shadow:         "{{colors.shadow.default.hex}}"
    property color scrim:          "{{colors.scrim.default.hex}}"

    // ── Terminal colors ────────────────────────────────────────────────────
    property color termBlack:      "{{colors.surface_dim.default.hex}}"
    property color termRed:        "{{colors.error.default.hex}}"
    property color termGreen:      "{{colors.tertiary.default.hex}}"
    property color termYellow:     "{{colors.tertiary_container.default.hex}}"
    property color termBlue:       "{{colors.secondary.default.hex}}"
    property color termMagenta:    "{{colors.primary_container.default.hex}}"
    property color termCyan:       "{{colors.secondary_container.default.hex}}"
    property color termWhite:      "{{colors.on_surface.default.hex}}"
}
