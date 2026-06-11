// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Control Center
// ═══════════════════════════════════════════════════════════════════════════════
// Slides in from the right (Hyprland layerrule animates the surface).
// Quick toggles · volume/brightness · media · live stats · real calendar.
// HyprlandFocusGrab closes it when you click anywhere else.
// ═══════════════════════════════════════════════════════════════════════════════

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.modules.common
import qs.modules.services

PanelWindow {
    id: cc
    WlrLayershell.namespace: "quickshell:controlCenter"
    exclusiveZone: 0
    color: "transparent"
    anchors { top: true; bottom: true; right: true }
    implicitWidth: 348

    visible: GlobalStates.controlCenterOpen

    // Register as a stats watcher only while visible.
    onVisibleChanged: SysInfoService.watchers += visible ? 1 : -1

    HyprlandFocusGrab {
        windows: [cc]
        active: cc.visible
        onCleared: GlobalStates.controlCenterOpen = false
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: Theme.spaceSm
        radius: Theme.radiusLg
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, Theme.opacityPanel)
        border { width: 1; color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3) }

        Flickable {
            anchors.fill: parent
            anchors.margins: Theme.spaceMd
            contentHeight: content.implicitHeight
            clip: true

            ColumnLayout {
                id: content
                width: parent.width
                spacing: Theme.spaceMd

                // ═══ Quick toggles ═══════════════════════════════════════════
                GridLayout {
                    columns: 2
                    columnSpacing: Theme.spaceSm
                    rowSpacing: Theme.spaceSm
                    Layout.fillWidth: true

                    QuickToggle {
                        icon: "󰖩"; label: "WiFi"
                        active: NetworkService.wifiEnabled
                        onToggled: NetworkService.toggleWifi()
                    }
                    QuickToggle {
                        icon: "󰂯"; label: "Bluetooth"
                        active: BluetoothService.enabled
                        onToggled: BluetoothService.togglePower()
                    }
                    QuickToggle {
                        icon: "󰌵"; label: "Night Light"
                        active: NightLightService.enabled
                        onToggled: NightLightService.toggle()
                    }
                    QuickToggle {
                        icon: "󰂛"; label: "Do Not Disturb"
                        active: Config.options.doNotDisturb
                        onToggled: Config.options.doNotDisturb = !Config.options.doNotDisturb
                    }
                    QuickToggle {
                        icon: "󰊴"; label: "Game Mode"
                        active: GamingService.active
                        onToggled: GamingService.toggle()
                    }
                    QuickToggle {
                        icon: "󰐥"; label: "Power"
                        active: false
                        onToggled: {
                            GlobalStates.controlCenterOpen = false
                            GlobalStates.powerMenuOpen = true
                        }
                    }
                }

                Divider { }

                // ═══ Sliders ═════════════════════════════════════════════════
                SliderRow {
                    Layout.fillWidth: true
                    icon: "󰕾"; label: "Volume"
                    value: AudioService.volume
                    onMoved: newValue => AudioService.setVolume(newValue)
                }
                SliderRow {
                    Layout.fillWidth: true
                    visible: BrightnessService.available
                    icon: "󰃟"; label: "Brightness"
                    value: Math.max(0, BrightnessService.brightness)
                    onMoved: newValue => BrightnessService.setBrightness(newValue)
                }

                Divider { }

                // ═══ Media ═══════════════════════════════════════════════════
                MprisPlayer { Layout.fillWidth: true }

                Divider { }

                // ═══ Live stats ══════════════════════════════════════════════
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spaceSm
                    StatChip { label: "CPU"; value: SysInfoService.cpuPercentStr; chipColor: Theme.primary }
                    StatChip { label: "GPU"; value: SysInfoService.gpuPercentStr; chipColor: Theme.secondary }
                    StatChip { label: "RAM"; value: SysInfoService.ramPercentStr; chipColor: Theme.colorSuccess }
                }

                // ═══ Expandable system details ═══════════════════════════════
                Rectangle {
                    id: detailCard
                    Layout.fillWidth: true
                    radius: Theme.radiusMd
                    color: Theme.surface2
                    clip: true
                    property bool expanded: false
                    implicitHeight: expanded ? detailColumn.implicitHeight + Theme.spaceMd * 2 : 44

                    Behavior on implicitHeight {
                        SpringAnimation { spring: 3.5; damping: 0.8; epsilon: 0.5 }
                    }

                    ColumnLayout {
                        id: detailColumn
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceMd }
                        spacing: Theme.spaceSm

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "󰍛  System"
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fontSizeSm
                                font.weight: Font.Bold
                                color: Theme.onSurface
                                Layout.fillWidth: true
                            }
                            Text {
                                text: detailCard.expanded ? "󰅃" : "󰅀"
                                font.family: Theme.fontMono
                                color: Theme.onSurfaceVar
                            }
                        }

                        GridLayout {
                            columns: 2
                            columnSpacing: Theme.spaceMd
                            rowSpacing: Theme.spaceXs
                            visible: detailCard.expanded

                            DetailLabel { text: "CPU Temp" }
                            DetailValue { text: SysInfoService.cpuTempStr }
                            DetailLabel { text: "GPU Temp" }
                            DetailValue { text: SysInfoService.gpuTempStr }
                            DetailLabel { text: "Kernel" }
                            DetailValue { text: SysInfoService.kernel }
                            DetailLabel { text: "Uptime" }
                            DetailValue { text: SysInfoService.uptime }
                        }
                    }

                    MouseArea {
                        anchors { left: parent.left; right: parent.right; top: parent.top }
                        height: 44
                        cursorShape: Qt.PointingHandCursor
                        onClicked: detailCard.expanded = !detailCard.expanded
                    }
                }

                Divider { }

                // ═══ Calendar (real month, today highlighted) ════════════════
                Rectangle {
                    Layout.fillWidth: true
                    radius: Theme.radiusMd
                    color: Theme.surface2
                    implicitHeight: calColumn.implicitHeight + Theme.spaceMd * 2

                    ColumnLayout {
                        id: calColumn
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceMd }
                        spacing: Theme.spaceSm

                        property date today: new Date()
                        property int firstDayOffset:
                            new Date(today.getFullYear(), today.getMonth(), 1).getDay()
                        property int daysInMonth:
                            new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate()

                        Text {
                            text: Qt.formatDate(calColumn.today, "MMMM yyyy")
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fontSizeSm
                            font.weight: Font.Bold
                            color: Theme.onSurface
                        }

                        GridLayout {
                            columns: 7
                            columnSpacing: 0
                            rowSpacing: 2
                            Layout.fillWidth: true

                            Repeater {
                                model: ["S", "M", "T", "W", "T", "F", "S"]
                                Text {
                                    required property string modelData
                                    text: modelData
                                    font.pixelSize: Theme.fontSizeXs
                                    color: Theme.onSurfaceVar
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.fillWidth: true
                                }
                            }

                            // Leading blanks to align day 1 with its weekday.
                            Repeater {
                                model: calColumn.firstDayOffset
                                Item { Layout.fillWidth: true; height: 26 }
                            }

                            Repeater {
                                model: calColumn.daysInMonth
                                Rectangle {
                                    required property int index
                                    readonly property bool isToday:
                                        index + 1 === calColumn.today.getDate()
                                    Layout.fillWidth: true
                                    height: 26
                                    radius: Theme.radiusFull
                                    color: isToday ? Theme.primaryGlow : "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: parent.index + 1
                                        font.pixelSize: Theme.fontSizeXs
                                        font.weight: parent.isToday ? Font.Bold : Font.Normal
                                        color: parent.isToday ? Theme.primary : Theme.onSurface
                                    }
                                }
                            }
                        }
                    }
                }

                Item { Layout.preferredHeight: Theme.spaceSm }
            }
        }
    }

    // ── Micro-components ────────────────────────────────────────────────────
    component Divider: Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Theme.outline
        opacity: 0.3
    }

    component StatChip: Rectangle {
        property string label: ""
        property string value: ""
        property color chipColor: Theme.primary
        Layout.fillWidth: true
        implicitHeight: 52
        radius: Theme.radiusMd
        color: Theme.surface2
        Column {
            anchors.centerIn: parent
            spacing: 2
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: parent.parent.value
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontSizeLg
                font.weight: Font.Bold
                color: parent.parent.chipColor
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: parent.parent.label
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontSizeXs
                color: Theme.onSurfaceVar
            }
        }
    }

    component DetailLabel: Text {
        font.pixelSize: Theme.fontSizeXs
        color: Theme.onSurfaceVar
    }
    component DetailValue: Text {
        font.pixelSize: Theme.fontSizeXs
        font.family: Theme.fontMono
        color: Theme.onSurface
    }
}
