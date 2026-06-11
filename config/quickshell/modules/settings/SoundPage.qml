// HamadaOS Settings — Sound (live PipeWire data)
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

    ColumnLayout {
        id: col
        width: root.width
        spacing: Theme.spaceLg

        SectionTitle { text: "Output" }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "󰕾"; font.family: Theme.fontMono; font.pixelSize: Theme.iconMd; color: Theme.onSurface }
            Slider {
                id: masterSlider
                from: 0.0; to: 1.0
                Layout.fillWidth: true
                Binding {
                    target: masterSlider; property: "value"
                    value: AudioService.volume; when: !masterSlider.pressed
                }
                onMoved: AudioService.setVolume(value)
            }
            Text {
                text: Math.round(AudioService.volume * 100) + "%"
                color: Theme.onSurfaceVar
                Layout.preferredWidth: 40
            }
        }

        ToggleRow {
            label: "Mute"
            checked: AudioService.muted
            onToggled: AudioService.toggleMute()
        }

        Text { text: "Output device"; font.pixelSize: Theme.fontSizeSm; color: Theme.onSurfaceVar }
        ComboBox {
            Layout.fillWidth: true
            model: AudioService.outputDevices.map(n => AudioService.deviceDisplayName(n))
            currentIndex: AudioService.outputDevices.findIndex(n => n === AudioService.sink)
            onActivated: index => AudioService.setDefaultSink(AudioService.outputDevices[index])
        }

        SectionTitle { text: "Per-app volume" }

        Text {
            visible: AudioService.outputAppNodes.length === 0
            text: "Nothing is playing audio."
            font.pixelSize: Theme.fontSizeSm
            color: Theme.onSurfaceVar
        }

        Repeater {
            model: AudioService.outputAppNodes

            RowLayout {
                id: appRow
                required property var modelData
                Layout.fillWidth: true
                spacing: Theme.spaceMd

                Text {
                    text: AudioService.appDisplayName(appRow.modelData)
                    font.pixelSize: Theme.fontSizeSm
                    color: Theme.onSurface
                    elide: Text.ElideRight
                    Layout.preferredWidth: 160
                }
                Slider {
                    id: appSlider
                    from: 0.0; to: 1.0
                    Layout.fillWidth: true
                    Binding {
                        target: appSlider; property: "value"
                        value: appRow.modelData.audio?.volume ?? 0
                        when: !appSlider.pressed
                    }
                    onMoved: AudioService.setAppVolume(appRow.modelData, value)
                }
                Text {
                    text: Math.round((appRow.modelData.audio?.volume ?? 0) * 100) + "%"
                    font.pixelSize: Theme.fontSizeXs
                    color: Theme.onSurfaceVar
                    Layout.preferredWidth: 36
                }
            }
        }

        SectionTitle { text: "Input" }

        ToggleRow {
            label: "Microphone mute"
            checked: AudioService.micMuted
            onToggled: AudioService.toggleMicMute()
        }

        Text { text: "Input device"; font.pixelSize: Theme.fontSizeSm; color: Theme.onSurfaceVar }
        ComboBox {
            Layout.fillWidth: true
            model: AudioService.inputDevices.map(n => AudioService.deviceDisplayName(n))
            currentIndex: AudioService.inputDevices.findIndex(n => n === AudioService.source)
            onActivated: index => AudioService.setDefaultSource(AudioService.inputDevices[index])
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: btTip.implicitHeight + Theme.spaceMd * 2
            radius: Theme.radiusMd
            color: Theme.surface2
            Text {
                id: btTip
                anchors { fill: parent; margins: Theme.spaceMd }
                text: "🎧 Bluetooth headset tip: pick \"Internal Microphone\" here and your " +
                      "headset keeps full A2DP audio quality while the mic still works. " +
                      "Using the headset's own mic forces the low-quality HFP profile — " +
                      "that's a Bluetooth protocol limit, not a bug."
                font.pixelSize: Theme.fontSizeXs
                color: Theme.onSurfaceVar
                wrapMode: Text.WordWrap
            }
        }

        RowLayout {
            spacing: Theme.spaceMd
            Button { text: "Advanced mixer…"; onClicked: Quickshell.execDetached(["pwvucontrol"]) }
            Button { text: "Audio effects…"; onClicked: Quickshell.execDetached(["easyeffects"]) }
        }

        Item { Layout.preferredHeight: Theme.spaceXl }
    }
}
