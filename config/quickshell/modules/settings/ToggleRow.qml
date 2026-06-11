// Label + optional description + switch. `toggled` only fires on user
// interaction (never on programmatic state sync) — no feedback loops.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

RowLayout {
    id: root
    property string label: ""
    property string description: ""
    property bool checked: false
    signal toggled(bool newState)

    Layout.fillWidth: true

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        Text {
            text: root.label
            font.family: Theme.fontSans
            font.pixelSize: Theme.fontSizeMd
            color: Theme.onSurface
        }
        Text {
            visible: root.description !== ""
            text: root.description
            font.pixelSize: Theme.fontSizeXs
            color: Theme.onSurfaceVar
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
    }

    Switch {
        checked: root.checked
        onToggled: root.toggled(checked)

        indicator: Rectangle {
            implicitWidth: 44
            implicitHeight: 24
            x: parent.leftPadding
            y: parent.height / 2 - height / 2
            radius: 12
            color: parent.checked ? Theme.primary : Theme.surface2
            border { width: 1; color: parent.checked ? Theme.primary : Theme.outline }
            Behavior on color { ColorAnimation { duration: Theme.durationFast } }

            Rectangle {
                x: parent.parent.checked ? parent.width - width - 3 : 3
                anchors.verticalCenter: parent.verticalCenter
                width: 18; height: 18; radius: 9
                color: parent.parent.checked ? Theme.onPrimary : Theme.onSurfaceVar
                Behavior on x { SpringAnimation { spring: 5.0; damping: 0.8 } }
            }
        }
    }
}
