// HamadaOS Settings — Display
// Per-monitor management like Windows "Display settings": every monitor gets
// resolution/refresh and scale controls, enable/disable, plus layout saving.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common
import qs.modules.services

Flickable {
    id: root
    contentHeight: col.implicitHeight
    clip: true

    Component.onCompleted: MonitorService.refresh()

    ColumnLayout {
        id: col
        width: root.width
        spacing: Theme.spaceLg

        SectionTitle { text: "Monitors" }

        // ── Mini layout map (relative positions, like Windows' numbered boxes) ─
        Item {
            Layout.fillWidth: true
            implicitHeight: 120
            visible: MonitorService.monitors.length > 0

            readonly property real worldW: Math.max(1,
                ...MonitorService.monitors.filter(m => !m.disabled).map(m => m.x + m.width / m.scale))
            readonly property real worldH: Math.max(1,
                ...MonitorService.monitors.filter(m => !m.disabled).map(m => m.y + m.height / m.scale))
            readonly property real mapScale: Math.min(width / worldW, height / worldH) * 0.95

            Repeater {
                model: MonitorService.monitors.filter(m => !m.disabled)
                Rectangle {
                    required property var modelData
                    required property int index
                    x: modelData.x * parent.mapScale
                    y: modelData.y * parent.mapScale
                    width: (modelData.width / modelData.scale) * parent.mapScale
                    height: (modelData.height / modelData.scale) * parent.mapScale
                    radius: 4
                    color: Theme.surface2
                    border { width: 1; color: Theme.primary }
                    Text {
                        anchors.centerIn: parent
                        text: (parent.index + 1) + "  " + parent.modelData.name
                        font.pixelSize: Theme.fontSizeXs
                        font.weight: Font.Bold
                        color: Theme.onSurface
                    }
                }
            }
        }

        // ── Per-monitor cards ───────────────────────────────────────────────
        Repeater {
            model: MonitorService.monitors

            Rectangle {
                id: monCard
                required property var modelData
                required property int index

                Layout.fillWidth: true
                implicitHeight: monCol.implicitHeight + Theme.spaceMd * 2
                radius: Theme.radiusMd
                color: Theme.surface2
                opacity: modelData.disabled ? 0.6 : 1.0

                ColumnLayout {
                    id: monCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceMd }
                    spacing: Theme.spaceSm

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: (monCard.index + 1) + ".  " + monCard.modelData.name
                            font.pixelSize: Theme.fontSizeMd
                            font.weight: Font.Bold
                            color: Theme.onSurface
                        }
                        Text {
                            Layout.fillWidth: true
                            text: monCard.modelData.description ?? ""
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.onSurfaceVar
                            elide: Text.ElideRight
                        }
                        Switch {
                            checked: !monCard.modelData.disabled
                            onToggled: MonitorService.setEnabled(monCard.modelData, checked)
                        }
                    }

                    GridLayout {
                        columns: 2
                        columnSpacing: Theme.spaceMd
                        rowSpacing: Theme.spaceSm
                        visible: !monCard.modelData.disabled
                        Layout.fillWidth: true

                        Text { text: "Resolution & refresh"; font.pixelSize: Theme.fontSizeSm; color: Theme.onSurfaceVar }
                        ComboBox {
                            id: modeCombo
                            Layout.fillWidth: true
                            model: monCard.modelData.availableModes ?? []
                            currentIndex: {
                                const cur = monCard.modelData.width + "x" + monCard.modelData.height
                                const rate = monCard.modelData.refreshRate ?? 60
                                const modes = monCard.modelData.availableModes ?? []
                                let best = 0
                                for (let i = 0; i < modes.length; i++) {
                                    if (modes[i].startsWith(cur) &&
                                        Math.abs(parseFloat(modes[i].split("@")[1]) - rate) < 1) { best = i; break }
                                }
                                return best
                            }
                            onActivated: MonitorService.applyMode(
                                monCard.modelData,
                                currentText.replace("Hz", ""),
                                scaleCombo.currentText)
                        }

                        Text { text: "Scale"; font.pixelSize: Theme.fontSizeSm; color: Theme.onSurfaceVar }
                        ComboBox {
                            id: scaleCombo
                            Layout.preferredWidth: 120
                            model: ["1", "1.25", "1.5", "1.6", "1.75", "2"]
                            currentIndex: {
                                const s = String(monCard.modelData.scale ?? 1)
                                const i = model.indexOf(s)
                                return i >= 0 ? i : 0
                            }
                            onActivated: MonitorService.applyMode(
                                monCard.modelData,
                                modeCombo.currentText.replace("Hz", ""),
                                currentText)
                        }
                    }
                }
            }
        }

        RowLayout {
            spacing: Theme.spaceMd
            Button {
                text: "Save this layout"
                onClicked: {
                    MonitorService.saveLayout()
                    Quickshell.execDetached(["notify-send", "-a", "HamadaOS",
                        "Display layout saved", "Written to monitors.conf — survives reboots"])
                }
            }
            Button {
                text: "Arrange monitors (drag & drop)…"
                onClicked: DisplayService.openMonitorArrangement()
            }
        }
        Text {
            text: "Changes apply instantly. \"Save this layout\" makes them permanent."
            font.pixelSize: Theme.fontSizeXs
            color: Theme.onSurfaceVar
        }

        SectionTitle { text: "Brightness"; visible: BrightnessService.available }

        RowLayout {
            visible: BrightnessService.available
            Layout.fillWidth: true
            Slider {
                from: 0.01; to: 1.0
                value: Math.max(0, BrightnessService.brightness)
                Layout.fillWidth: true
                onMoved: BrightnessService.setBrightness(value)
            }
            Text {
                text: Math.round(Math.max(0, BrightnessService.brightness) * 100) + "%"
                color: Theme.onSurfaceVar
                Layout.preferredWidth: 44
            }
        }

        SectionTitle { text: "Night Light" }

        ToggleRow {
            label: "Night light"
            description: "Warm color filter via hyprsunset — easier on the eyes after dark."
            checked: NightLightService.enabled
            onToggled: NightLightService.toggle()
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Warmth"; color: Theme.onSurface; font.pixelSize: Theme.fontSizeSm; Layout.preferredWidth: 70 }
            Slider {
                from: 2500; to: 5500; stepSize: 100
                value: NightLightService.temperature
                Layout.fillWidth: true
                onMoved: NightLightService.setTemperature(value)
            }
            Text {
                text: Math.round(NightLightService.temperature) + "K"
                color: Theme.onSurfaceVar
                Layout.preferredWidth: 52
            }
        }

        SectionTitle { text: "Adaptive Sync" }

        RowLayout {
            Text { text: "VRR (FreeSync / G-Sync)"; color: Theme.onSurface; font.pixelSize: Theme.fontSizeMd; Layout.fillWidth: true }
            ComboBox {
                model: ["Off", "Always on", "Fullscreen only"]
                currentIndex: DisplayService.vrrMode
                onActivated: DisplayService.setVrr(currentIndex)
            }
        }

        Item { Layout.preferredHeight: Theme.spaceXl }
    }
}
