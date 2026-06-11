// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Quick Toggle (Control Center grid button)
// ═══════════════════════════════════════════════════════════════════════════════

import QtQuick
import QtQuick.Layouts
import qs

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property bool active: false
    signal toggled()

    Layout.fillWidth: true
    implicitHeight: 64
    radius: Theme.radiusMd
    color: active ? Theme.primaryGlow : Theme.surface2
    border {
        width: 1
        color: root.active ? Theme.primary
             : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.4)
    }

    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.durationFast } }

    scale: ma.pressed ? 0.96 : 1.0
    Behavior on scale { SpringAnimation { spring: 5.0; damping: 0.8 } }

    Column {
        anchors.centerIn: parent
        spacing: Theme.spaceXs

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.icon
            font.family: Theme.fontMono
            font.pixelSize: Theme.iconLg
            color: root.active ? Theme.primary : Theme.onSurface
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            font.family: Theme.fontSans
            font.pixelSize: Theme.fontSizeXs
            color: root.active ? Theme.primary : Theme.onSurfaceVar
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
