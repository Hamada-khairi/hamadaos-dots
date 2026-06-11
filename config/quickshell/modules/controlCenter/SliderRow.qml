// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Slider Row (icon + slider + value)
// ═══════════════════════════════════════════════════════════════════════════════
// `moved(newValue)` fires only on user interaction — external value changes
// (hardware keys, other apps) update the handle without re-emitting, which
// kills the classic slider/service binding loop.
// ═══════════════════════════════════════════════════════════════════════════════

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

Item {
    id: root

    property string icon: ""
    property string label: ""
    property real value: 0.5
    signal moved(real newValue)

    implicitHeight: 36

    RowLayout {
        anchors.fill: parent
        spacing: Theme.spaceSm

        Text {
            text: root.icon
            font.family: Theme.fontMono
            font.pixelSize: Theme.iconMd
            color: Theme.onSurface
            Layout.preferredWidth: 24
        }

        Slider {
            id: slider
            Layout.fillWidth: true
            from: 0.0
            to: 1.0

            // One-way: service → handle, unless the user is dragging.
            Binding {
                target: slider; property: "value"; value: root.value
                when: !slider.pressed
            }

            onMoved: root.moved(slider.value)

            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: slider.availableWidth
                height: 5
                radius: 2.5
                color: Theme.surface2

                Rectangle {
                    width: slider.visualPosition * parent.width
                    height: parent.height
                    radius: 2.5
                    color: Theme.primary
                }
            }

            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                implicitWidth: 16
                implicitHeight: 16
                radius: 8
                color: Theme.primary
                scale: slider.pressed ? 1.25 : 1.0
                Behavior on scale { SpringAnimation { spring: 5.0; damping: 0.7 } }
            }
        }

        Text {
            text: Math.round((slider.pressed ? slider.value : root.value) * 100) + "%"
            font.family: Theme.fontSans
            font.pixelSize: Theme.fontSizeSm
            color: Theme.onSurface
            Layout.preferredWidth: 38
            horizontalAlignment: Text.AlignRight
        }
    }
}
