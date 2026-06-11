// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Bar
// ═══════════════════════════════════════════════════════════════════════════════
// One bar per monitor (Variants over Quickshell.screens). PanelWindow anchors
// are layer-shell booleans; position follows Config.options.barPosition.
// Namespace "quickshell:bar" is targeted by Hyprland layerrules for blur.
// ═══════════════════════════════════════════════════════════════════════════════

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules.common

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bar
        required property var modelData
        screen: modelData

        WlrLayershell.namespace: "quickshell:bar"

        anchors {
            top: Config.options.barPosition === "top"
            bottom: Config.options.barPosition === "bottom"
            left: true
            right: true
        }

        implicitHeight: 40
        exclusiveZone: 40

        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b,
                       Theme.opacityPanel)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spaceLg
            anchors.rightMargin: Theme.spaceLg
            spacing: Theme.spaceSm

            // ── Left: launcher button + workspaces + active window ─────────
            Rectangle {
                width: 32; height: 28; radius: Theme.radiusSm
                color: launcherMa.containsMouse ? Theme.primaryGlow : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                Text {
                    anchors.centerIn: parent
                    text: "󰣇"
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSizeLg
                    color: Theme.primary
                }
                MouseArea {
                    id: launcherMa
                    anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: GlobalStates.launcherOpen = !GlobalStates.launcherOpen
                }
            }

            WorkspaceIndicator { Layout.alignment: Qt.AlignVCenter }

            ActiveWindow {
                Layout.alignment: Qt.AlignVCenter
                Layout.maximumWidth: bar.width * 0.25
            }

            Item { Layout.fillWidth: true }

            // ── Center: clock ───────────────────────────────────────────────
            ClockWidget { Layout.alignment: Qt.AlignVCenter }

            Item { Layout.fillWidth: true }

            // ── Right: tray + status + control center ──────────────────────
            SysTray { Layout.alignment: Qt.AlignVCenter }
            StatusIcons { Layout.alignment: Qt.AlignVCenter }
        }
    }
}
