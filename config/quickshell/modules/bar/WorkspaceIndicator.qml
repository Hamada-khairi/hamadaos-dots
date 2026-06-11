// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Workspace Indicator (animated dots, live Hyprland data)
// ═══════════════════════════════════════════════════════════════════════════════
// Bound directly to Quickshell.Hyprland — updates the instant the compositor
// switches workspace, no polling. The focused dot stretches into a pill with
// real spring physics; occupied workspaces are brighter than empty ones.
// ═══════════════════════════════════════════════════════════════════════════════

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs

RowLayout {
    id: root
    spacing: 6

    property int shownWorkspaces: 10
    readonly property int focusedId: Hyprland.focusedWorkspace?.id ?? 1

    function workspaceExists(id) {
        return Hyprland.workspaces.values.some(ws => ws.id === id)
    }

    Repeater {
        model: root.shownWorkspaces

        Rectangle {
            id: dot
            required property int index
            readonly property int wsId: index + 1
            readonly property bool active: wsId === root.focusedId
            readonly property bool occupied: root.workspaceExists(wsId)

            width: active ? 24 : 8
            height: 8
            radius: 4
            color: active ? Theme.primary
                 : occupied ? Theme.onSurfaceVar
                 : Theme.outline

            Behavior on width {
                SpringAnimation { spring: 3.0; damping: 0.8; epsilon: 0.5 }
            }
            Behavior on color {
                ColorAnimation { duration: Theme.durationFast }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + dot.wsId)
            }
        }
    }
}
