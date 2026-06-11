// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Power Menu (replaces wlogout)
// ═══════════════════════════════════════════════════════════════════════════════
// Full-screen overlay with Lock / Suspend / Logout / Reboot / Shutdown.
// Keyboard: arrows + Enter, Esc cancels, or press the underlined letter.
// ═══════════════════════════════════════════════════════════════════════════════

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules.common

PanelWindow {
    id: menu
    WlrLayershell.namespace: "quickshell:session"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusiveZone: 0
    color: Qt.rgba(0, 0, 0, 0.6)
    anchors { top: true; bottom: true; left: true; right: true }

    property int selectedIndex: 0

    readonly property var actions: [
        { icon: "󰌾", label: "Lock",     key: "L", cmd: ["loginctl", "lock-session"] },
        { icon: "󰒲", label: "Suspend",  key: "S", cmd: ["systemctl", "suspend"] },
        { icon: "󰍃", label: "Logout",   key: "O", cmd: ["hyprctl", "dispatch", "exit"] },
        { icon: "󰜉", label: "Reboot",   key: "R", cmd: ["systemctl", "reboot"] },
        { icon: "󰐥", label: "Shutdown", key: "P", cmd: ["systemctl", "poweroff"] }
    ]

    function run(action) {
        GlobalStates.powerMenuOpen = false
        Quickshell.execDetached(action.cmd)
    }

    MouseArea {
        anchors.fill: parent
        onClicked: GlobalStates.powerMenuOpen = false
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: GlobalStates.powerMenuOpen = false
        Keys.onLeftPressed: menu.selectedIndex = Math.max(0, menu.selectedIndex - 1)
        Keys.onRightPressed: menu.selectedIndex = Math.min(menu.actions.length - 1, menu.selectedIndex + 1)
        Keys.onReturnPressed: menu.run(menu.actions[menu.selectedIndex])
        Keys.onPressed: event => {
            const hit = menu.actions.find(a => a.key.toLowerCase() === event.text.toLowerCase())
            if (hit) menu.run(hit)
        }
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: Theme.spaceLg

        Repeater {
            model: menu.actions

            Rectangle {
                id: card
                required property var modelData
                required property int index
                readonly property bool selected: index === menu.selectedIndex

                width: 140
                height: 150
                radius: Theme.radiusLg
                color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b,
                               selected ? 0.98 : 0.88)
                border {
                    width: selected ? 2 : 1
                    color: selected ? Theme.primary
                         : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.4)
                }

                scale: selected ? 1.06 : 1.0
                Behavior on scale { SpringAnimation { spring: 4.0; damping: 0.75 } }
                Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Theme.spaceMd

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: card.modelData.icon
                        font.family: Theme.fontMono
                        font.pixelSize: 42
                        color: card.modelData.label === "Shutdown" ? Theme.colorDanger
                             : card.selected ? Theme.primary : Theme.onSurface
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: card.modelData.label
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fontSizeMd
                        font.weight: Font.Medium
                        color: Theme.onSurface
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: menu.selectedIndex = card.index
                    onClicked: menu.run(card.modelData)
                }
            }
        }
    }
}
