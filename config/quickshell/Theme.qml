// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Design Token System
// ═══════════════════════════════════════════════════════════════════════════════
// Every visible element on the HamadaOS desktop derives its colors, typography,
// spacing, radius, animation duration, and opacity from this singleton.
//
// Change a wallpaper → matugen rewrites GeneratedColors.qml → Quickshell
// hot-reloads it → Theme bindings propagate → every component on screen
// updates in the same frame.
//
// Components bind to Theme.primary, never GeneratedColors.primary directly —
// the indirection lets us change how tokens are derived without touching
// any component file.
// ═══════════════════════════════════════════════════════════════════════════════

pragma Singleton
import QtQuick
import Quickshell
import qs.modules.common

Singleton {
    id: root

    // ═══════════════════════════════════════════════════════════════════════
    // COLORS — sourced from GeneratedColors (matugen output, same folder)
    // ═══════════════════════════════════════════════════════════════════════

    property color primary:        GeneratedColors.primary
    property color onPrimary:      GeneratedColors.onPrimary
    property color surface:        GeneratedColors.surface
    property color surfaceVariant: GeneratedColors.surfaceVariant
    property color onSurface:      GeneratedColors.onSurface
    property color onSurfaceVar:   GeneratedColors.onSurfaceVar
    property color outline:        GeneratedColors.outline
    property color error:          GeneratedColors.error
    property color secondary:      GeneratedColors.secondary
    property color tertiary:       GeneratedColors.tertiary
    property color surfaceBright:  GeneratedColors.surfaceBright
    property color surfaceDim:     GeneratedColors.surfaceDim
    property color shadow:         GeneratedColors.shadow
    property color scrim:          GeneratedColors.scrim

    // ── Derived surface tones (computed, never set by matugen) ────────────
    property color surface1:
        Qt.rgba(surfaceVariant.r, surfaceVariant.g, surfaceVariant.b, 0.70)
    property color surface2:
        Qt.rgba(surfaceVariant.r, surfaceVariant.g, surfaceVariant.b, 0.40)
    property color primaryGlow:
        Qt.rgba(primary.r, primary.g, primary.b, 0.25)
    property color hoverOverlay:
        Qt.rgba(onSurface.r, onSurface.g, onSurface.b, opacityHover)

    // ── Status colors ──────────────────────────────────────────────────────
    property color colorSuccess: "#a6e3a1"
    property color colorWarning: "#f9e2af"
    property color colorDanger:  "#f38ba8"
    property color colorInfo:    "#89b4fa"

    // ═══════════════════════════════════════════════════════════════════════
    // TYPOGRAPHY — sizes scale with the accessibility text-scale setting
    // ═══════════════════════════════════════════════════════════════════════

    property string fontSans:    "Geist"
    property string fontMono:    "JetBrainsMono Nerd Font"
    property string fontDisplay: "Geist"

    readonly property real _ts: Config.options.textScale

    property real fontSizeXs:  10 * _ts
    property real fontSizeSm:  12 * _ts
    property real fontSizeMd:  14 * _ts
    property real fontSizeLg:  16 * _ts
    property real fontSizeXl:  20 * _ts
    property real fontSize2xl: 28 * _ts

    // ═══════════════════════════════════════════════════════════════════════
    // SPACING — 4px grid
    // ═══════════════════════════════════════════════════════════════════════

    property real spaceXs:   4
    property real spaceSm:   8
    property real spaceMd:  12
    property real spaceLg:  16
    property real spaceXl:  24
    property real space2xl: 32

    // ═══════════════════════════════════════════════════════════════════════
    // BORDER RADIUS
    // ═══════════════════════════════════════════════════════════════════════

    property real radiusSm:    6
    property real radiusMd:   12
    property real radiusLg:   16
    property real radiusXl:   24
    property real radiusFull: 999

    // ═══════════════════════════════════════════════════════════════════════
    // MOTION — QML-side durations (ms), scaled by the animation-speed slider
    // so shell animations and Hyprland animations stay in step.
    // ═══════════════════════════════════════════════════════════════════════

    readonly property real _speed: Config.options.animations
        ? Math.max(0.25, Config.options.animationSpeed) : 1000

    property int durationFast:   Math.round(150 / _speed)
    property int durationNormal: Math.round(280 / _speed)
    property int durationSlow:   Math.round(450 / _speed)

    // ═══════════════════════════════════════════════════════════════════════
    // OPACITY
    // ═══════════════════════════════════════════════════════════════════════

    property real opacityPanel:    Config.options.blur ? 0.85 : 0.97
    property real opacityPopup:    Config.options.blur ? 0.92 : 0.98
    property real opacityDisabled: 0.38
    property real opacityOverlay:  0.50
    property real opacityHover:    0.08
    property real opacityPressed:  0.12

    // ═══════════════════════════════════════════════════════════════════════
    // ICON SIZES
    // ═══════════════════════════════════════════════════════════════════════

    property real iconSm: 16
    property real iconMd: 20
    property real iconLg: 24
    property real iconXl: 32
}
