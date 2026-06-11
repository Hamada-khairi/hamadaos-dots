// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Dock (pinned + running apps)
// ═══════════════════════════════════════════════════════════════════════════════
// Pinned apps come from Config.options.dockPinnedApps (desktop entry IDs —
// editable from Settings later). Running apps appear automatically with a
// dot indicator, macOS style. Icons are real theme icons via DesktopEntries.
// ═══════════════════════════════════════════════════════════════════════════════

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.modules.common

PanelWindow {
    id: dock
    WlrLayershell.namespace: "quickshell:dock"
    exclusiveZone: Config.options.dockAutoHide ? 0 : 62
    color: "transparent"
    anchors { bottom: true }
    margins { bottom: 6 }

    implicitHeight: 62
    implicitWidth: dockRow.implicitWidth + Theme.spaceXl * 2

    // ── Model: pinned entries + running apps not already pinned ────────────
    readonly property list<var> pinnedEntries:
        Config.options.dockPinnedApps
            .map(id => DesktopEntries.byId(id) ?? DesktopEntries.heuristicLookup(id))
            .filter(e => e !== null)

    readonly property list<var> runningClasses: {
        const classes = []
        for (const t of (Hyprland.toplevels?.values ?? [])) {
            const cls = t.lastIpcObject?.class ?? ""
            if (cls && !classes.includes(cls)) classes.push(cls)
        }
        return classes
    }

    function isRunning(entry) {
        if (!entry) return false
        return runningClasses.some(cls => {
            const found = DesktopEntries.heuristicLookup(cls)
            return found && found.id === entry.id
        })
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusLg
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, Theme.opacityPanel)
        border { width: 1; color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3) }

        RowLayout {
            id: dockRow
            anchors.centerIn: parent
            spacing: Theme.spaceSm

            Repeater {
                model: dock.pinnedEntries

                Item {
                    id: dockItem
                    required property var modelData
                    readonly property bool running: dock.isRunning(modelData)

                    implicitWidth: 46
                    implicitHeight: 50

                    Rectangle {
                        id: iconBg
                        width: 44; height: 44
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: Theme.radiusMd
                        color: itemMa.containsMouse ? Theme.primaryGlow : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                        // macOS-style hover lift
                        y: itemMa.containsMouse ? -4 : 0
                        Behavior on y { SpringAnimation { spring: 4.0; damping: 0.7 } }

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 32
                            source: Quickshell.iconPath(dockItem.modelData.icon,
                                                        "application-x-executable")
                        }
                    }

                    // Running indicator dot
                    Rectangle {
                        visible: dockItem.running
                        width: 5; height: 5; radius: 2.5
                        color: Theme.primary
                        anchors {
                            bottom: parent.bottom
                            horizontalCenter: parent.horizontalCenter
                        }
                    }

                    MouseArea {
                        id: itemMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dockItem.modelData.execute()
                    }
                }
            }
        }
    }
}
