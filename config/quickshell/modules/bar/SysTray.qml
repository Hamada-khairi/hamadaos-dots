// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — System Tray (StatusNotifierItem host)
// ═══════════════════════════════════════════════════════════════════════════════
// Real tray: nm-applet, blueman, KDE Connect, Steam, Discord all dock here.
// Left-click activates, right-click opens the item's native menu.
// ═══════════════════════════════════════════════════════════════════════════════

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs

RowLayout {
    id: root
    spacing: Theme.spaceXs

    Repeater {
        model: SystemTray.items

        Rectangle {
            id: trayItem
            required property SystemTrayItem modelData

            width: 28; height: 28
            radius: Theme.radiusSm
            color: ma.containsMouse ? Theme.hoverOverlay : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.durationFast } }

            IconImage {
                anchors.centerIn: parent
                implicitSize: Theme.iconSm
                source: trayItem.modelData.icon
            }

            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton && !trayItem.modelData.onlyMenu) {
                        trayItem.modelData.activate()
                    } else if (mouse.button === Qt.MiddleButton) {
                        trayItem.modelData.secondaryActivate()
                    } else if (trayItem.modelData.hasMenu) {
                        menuAnchor.open()
                    }
                }
            }

            QsMenuAnchor {
                id: menuAnchor
                menu: trayItem.modelData.menu
                anchor.window: trayItem.QsWindow.window
                anchor.item: trayItem
                anchor.edges: Edges.Bottom
                anchor.gravity: Edges.Bottom
            }
        }
    }
}
