// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Appearance (computed style properties)
// ═══════════════════════════════════════════════════════════════════════════════
// Properties that depend on both Theme tokens and Config settings.
// ═══════════════════════════════════════════════════════════════════════════════
pragma Singleton
import QtQuick
import Quickshell
import qs

Singleton {
    id: root
    property real effectiveBlur: Config.options.blur ? Config.options.blurStrength : 0.0
    property real effectiveOpacity: Config.options.blur ? Theme.opacityPanel : 0.97
    property int effectiveAnimationDuration: Config.options.animations ? Theme.durationNormal : 0
}
