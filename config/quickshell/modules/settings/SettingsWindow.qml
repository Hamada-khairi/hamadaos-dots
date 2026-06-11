// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Settings App
// ═══════════════════════════════════════════════════════════════════════════════
// A real window (FloatingWindow), not a layer surface — so it gets the
// hyprbars title bar, float-by-default rules, Alt+Tab entry, and behaves
// exactly like a native app. Navigation rail on the left, page Loader right.
// ═══════════════════════════════════════════════════════════════════════════════

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common

FloatingWindow {
    id: settings
    title: "HamadaOS Settings"
    implicitWidth: 760
    implicitHeight: 600
    color: Theme.surface

    visible: GlobalStates.settingsOpen
    onVisibleChanged: if (!visible) GlobalStates.settingsOpen = false

    property string currentPage: "Appearance"

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ── Navigation rail ──────────────────────────────────────────────────
        Rectangle {
            Layout.preferredWidth: 210
            Layout.fillHeight: true
            color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g,
                           Theme.surfaceVariant.b, 0.5)

            ColumnLayout {
                anchors { fill: parent; margins: Theme.spaceMd }
                spacing: Theme.spaceXs

                Text {
                    text: "HamadaOS"
                    font.family: Theme.fontDisplay
                    font.pixelSize: Theme.fontSizeLg
                    font.weight: Font.Bold
                    color: Theme.primary
                    Layout.leftMargin: Theme.spaceMd
                    Layout.topMargin: Theme.spaceSm
                    Layout.bottomMargin: Theme.spaceMd
                }

                Repeater {
                    model: [
                        { icon: "󰗠", label: "Health" },
                        { icon: "󰏘", label: "Appearance" },
                        { icon: "󰍹", label: "Display" },
                        { icon: "󰕾", label: "Sound" },
                        { icon: "󰖩", label: "Network" },
                        { icon: "󰂯", label: "Bluetooth" },
                        { icon: "󰋜", label: "Default Apps" },
                        { icon: "󰏗", label: "Compatibility" },
                        { icon: "󰑮", label: "Animations" },
                        { icon: "󰊴", label: "Gaming" },
                        { icon: "󰒃", label: "Security" },
                        { icon: "󱁤", label: "Tools" },
                        { icon: "󰋗", label: "About" }
                    ]

                    Rectangle {
                        id: navItem
                        required property var modelData
                        readonly property bool active: settings.currentPage === modelData.label

                        Layout.fillWidth: true
                        implicitHeight: 42
                        radius: Theme.radiusMd
                        color: active ? Theme.primaryGlow
                             : navMa.containsMouse ? Theme.hoverOverlay : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                        RowLayout {
                            anchors { fill: parent; leftMargin: Theme.spaceMd }
                            spacing: Theme.spaceMd

                            Text {
                                text: navItem.modelData.icon
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.iconMd
                                color: navItem.active ? Theme.primary : Theme.onSurface
                            }
                            Text {
                                text: navItem.modelData.label
                                font.family: Theme.fontSans
                                font.pixelSize: Theme.fontSizeMd
                                color: navItem.active ? Theme.primary : Theme.onSurface
                            }
                        }

                        MouseArea {
                            id: navMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: settings.currentPage = navItem.modelData.label
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        // ── Page content ─────────────────────────────────────────────────────
        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: Theme.spaceXl
            source: {
                switch (settings.currentPage) {
                case "Health":     return "HealthPage.qml"
                case "Appearance": return "AppearancePage.qml"
                case "Display":    return "DisplayPage.qml"
                case "Sound":      return "SoundPage.qml"
                case "Network":    return "NetworkPage.qml"
                case "Bluetooth":  return "BluetoothPage.qml"
                case "Default Apps": return "DefaultAppsPage.qml"
                case "Compatibility": return "CompatibilityPage.qml"
                case "Animations": return "AnimationPage.qml"
                case "Gaming":     return "GamingPage.qml"
                case "Security":   return "SecurityPage.qml"
                case "Tools":      return "ToolsPage.qml"
                default:           return "AboutPage.qml"
                }
            }
        }
    }
}
