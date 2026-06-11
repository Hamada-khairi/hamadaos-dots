// HamadaOS Settings — Animations (presets + speed, live preview)
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
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

        SectionTitle { text: "Animation style" }

        ToggleRow {
            label: "Animations"
            description: "Compositor and shell animations. Gaming mode disables them automatically."
            checked: Config.options.animations
            onToggled: newState => AnimationService.setEnabled(newState)
        }

        GridLayout {
            columns: 2
            columnSpacing: Theme.spaceSm
            rowSpacing: Theme.spaceSm
            Layout.fillWidth: true

            Repeater {
                model: Object.keys(AnimationService.presets)

                Rectangle {
                    id: presetCard
                    required property string modelData
                    readonly property bool active: Config.options.animationPreset === modelData

                    Layout.fillWidth: true
                    implicitHeight: 72
                    radius: Theme.radiusMd
                    color: active ? Theme.primaryGlow : Theme.surface2
                    border { width: 1; color: presetCard.active ? Theme.primary : "transparent" }
                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                    ColumnLayout {
                        anchors { fill: parent; margins: Theme.spaceMd }
                        spacing: 2
                        Text {
                            text: presetCard.modelData
                            font.pixelSize: Theme.fontSizeSm
                            font.weight: Font.Bold
                            color: presetCard.active ? Theme.primary : Theme.onSurface
                        }
                        Text {
                            Layout.fillWidth: true
                            text: AnimationService.presets[presetCard.modelData].description
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.onSurfaceVar
                            wrapMode: Text.WordWrap
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AnimationService.applyPreset(presetCard.modelData)
                    }
                }
            }
        }

        SectionTitle { text: "Speed" }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "0.25×"; font.pixelSize: Theme.fontSizeXs; color: Theme.onSurfaceVar }
            Slider {
                id: speedSlider
                from: 0.25; to: 3.0; stepSize: 0.25
                value: Config.options.animationSpeed
                Layout.fillWidth: true
                // Apply on release — every change rewrites the Hyprland config.
                onPressedChanged: if (!pressed) AnimationService.setSpeed(value)
            }
            Text { text: "3×"; font.pixelSize: Theme.fontSizeXs; color: Theme.onSurfaceVar }
            Text {
                text: Config.options.animationSpeed + "×"
                font.weight: Font.Bold
                font.pixelSize: Theme.fontSizeSm
                color: Theme.primary
                Layout.preferredWidth: 48
            }
        }

        SectionTitle { text: "Preview" }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 110
            radius: Theme.radiusMd
            color: Theme.surface2
            clip: true

            Rectangle {
                id: previewBox
                width: 70; height: 70
                radius: Theme.radiusMd
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
                x: 20
                Text {
                    anchors.centerIn: parent
                    text: "󰊠"
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.iconLg
                    color: Theme.onPrimary
                }

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: root.visible && Config.options.animations
                    NumberAnimation {
                        to: 460
                        duration: Math.round(900 / Math.max(0.25, Config.options.animationSpeed))
                        easing.type: Easing.OutBack
                    }
                    PauseAnimation { duration: 350 }
                    NumberAnimation {
                        to: 20
                        duration: Math.round(900 / Math.max(0.25, Config.options.animationSpeed))
                        easing.type: Easing.OutCubic
                    }
                    PauseAnimation { duration: 350 }
                }
            }
        }

        Item { Layout.preferredHeight: Theme.spaceXl }
    }
}
