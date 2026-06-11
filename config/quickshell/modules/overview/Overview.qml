// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Task Overview (live workspaces + windows)
// ═══════════════════════════════════════════════════════════════════════════════
// Real data from Quickshell.Hyprland: every workspace that exists, with the
// windows on it. Click a workspace to jump, click a window to focus it.
// (hyprexpo on Super+Grave provides the compositor-level thumbnail grid;
// this overlay is the structured, clickable list view.)
// ═══════════════════════════════════════════════════════════════════════════════

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import qs
import qs.modules.common

PanelWindow {
    id: overview
    WlrLayershell.namespace: "quickshell:overview"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusiveZone: 0
    color: Qt.rgba(0, 0, 0, 0.55)
    anchors { top: true; bottom: true; left: true; right: true }

    Component.onCompleted: {
        Hyprland.refreshWorkspaces()
        Hyprland.refreshToplevels()
    }

    readonly property list<var> workspaces:
        [...Hyprland.workspaces.values]
            .filter(ws => ws.id > 0)
            .sort((a, b) => a.id - b.id)

    MouseArea {
        anchors.fill: parent
        onClicked: GlobalStates.overviewOpen = false
    }

    Item {
        anchors.fill: parent
        Keys.onEscapePressed: GlobalStates.overviewOpen = false
        focus: true
    }

    ColumnLayout {
        anchors { fill: parent; margins: Theme.space2xl }
        spacing: Theme.spaceLg

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Workspaces"
            font.family: Theme.fontDisplay
            font.pixelSize: Theme.fontSize2xl
            font.weight: Font.Bold
            color: "white"
        }

        GridLayout {
            Layout.alignment: Qt.AlignHCenter
            columns: Math.min(4, Math.max(2, Math.ceil(Math.sqrt(overview.workspaces.length))))
            columnSpacing: Theme.spaceLg
            rowSpacing: Theme.spaceLg

            Repeater {
                model: overview.workspaces

                Rectangle {
                    id: wsCard
                    required property var modelData
                    readonly property bool focused:
                        modelData.id === (Hyprland.focusedWorkspace?.id ?? -1)
                    readonly property list<var> windows:
                        [...(Hyprland.toplevels?.values ?? [])]
                            .filter(t => t.workspace?.id === modelData.id)

                    width: 280
                    height: 190
                    radius: Theme.radiusLg
                    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.92)
                    border {
                        width: focused ? 2 : 1
                        color: focused ? Theme.primary
                             : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.5)
                    }

                    scale: cardMa.containsMouse ? 1.03 : 1.0
                    Behavior on scale { SpringAnimation { spring: 4.0; damping: 0.8 } }

                    ColumnLayout {
                        anchors { fill: parent; margins: Theme.spaceMd }
                        spacing: Theme.spaceXs

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "Workspace " + wsCard.modelData.id
                                font.family: Theme.fontSans
                                font.pixelSize: Theme.fontSizeSm
                                font.weight: Font.Bold
                                color: wsCard.focused ? Theme.primary : Theme.onSurface
                                Layout.fillWidth: true
                            }
                            Text {
                                text: wsCard.windows.length === 1 ? "1 window"
                                    : wsCard.windows.length + " windows"
                                font.pixelSize: Theme.fontSizeXs
                                color: Theme.onSurfaceVar
                            }
                        }

                        // Window list — click to focus that window.
                        Repeater {
                            model: wsCard.windows.slice(0, 4)

                            Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 28
                                radius: Theme.radiusSm
                                color: winMa.containsMouse ? Theme.primaryGlow : Theme.surface2

                                RowLayout {
                                    anchors { fill: parent; leftMargin: Theme.spaceSm; rightMargin: Theme.spaceSm }
                                    spacing: Theme.spaceSm
                                    IconImage {
                                        implicitSize: 16
                                        source: {
                                            const entry = DesktopEntries.heuristicLookup(parent.parent.modelData.lastIpcObject?.class ?? "")
                                            return Quickshell.iconPath(entry?.icon ?? "", "application-x-executable")
                                        }
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: parent.parent.modelData.title
                                        font.pixelSize: Theme.fontSizeXs
                                        color: Theme.onSurface
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    id: winMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const addr = String(parent.modelData.address).replace(/^0x/, "")
                                        Hyprland.dispatch("focuswindow address:0x" + addr)
                                        GlobalStates.overviewOpen = false
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }

                    MouseArea {
                        id: cardMa
                        anchors.fill: parent
                        hoverEnabled: true
                        z: -1
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Hyprland.dispatch("workspace " + wsCard.modelData.id)
                            GlobalStates.overviewOpen = false
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
