// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Active Window Title (bar, left section)
// ═══════════════════════════════════════════════════════════════════════════════

import QtQuick
import Quickshell.Hyprland
import qs

Text {
    text: Hyprland.activeToplevel?.title ?? ""
    visible: text !== ""
    font.family: Theme.fontSans
    font.pixelSize: Theme.fontSizeSm
    color: Theme.onSurfaceVar
    elide: Text.ElideRight
    maximumLineCount: 1
}
