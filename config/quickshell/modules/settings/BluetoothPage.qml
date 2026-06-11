// HamadaOS Settings — Bluetooth (native Quickshell.Bluetooth, zero parsing)
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

        SectionTitle { text: "Bluetooth" }

        Text {
            visible: !BluetoothService.available
            text: "No Bluetooth adapter found."
            font.pixelSize: Theme.fontSizeSm
            color: Theme.onSurfaceVar
        }

        ToggleRow {
            visible: BluetoothService.available
            label: "Bluetooth"
            description: BluetoothService.connectedDevices.length > 0
                ? BluetoothService.connectedDevices.length + " device(s) connected"
                : "On, nothing connected"
            checked: BluetoothService.enabled
            onToggled: BluetoothService.togglePower()
        }

        ToggleRow {
            visible: BluetoothService.available && BluetoothService.enabled
            label: "Discover new devices"
            description: "Scan for nearby devices in pairing mode."
            checked: BluetoothService.discovering
            onToggled: BluetoothService.toggleDiscovery()
        }

        SectionTitle { text: "Devices"; visible: BluetoothService.enabled }

        Repeater {
            model: BluetoothService.devices

            Rectangle {
                id: devRow
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 46
                radius: Theme.radiusSm
                color: devMa.containsMouse ? Theme.hoverOverlay : "transparent"

                RowLayout {
                    anchors { fill: parent; leftMargin: Theme.spaceSm; rightMargin: Theme.spaceSm }
                    spacing: Theme.spaceMd

                    Text {
                        text: BluetoothService.deviceIcon(devRow.modelData)
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.iconMd
                        color: devRow.modelData.connected ? Theme.primary : Theme.onSurfaceVar
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            text: devRow.modelData.name || devRow.modelData.address
                            font.pixelSize: Theme.fontSizeSm
                            color: Theme.onSurface
                            elide: Text.ElideRight
                        }
                        Text {
                            text: devRow.modelData.connected ? "Connected"
                                : devRow.modelData.paired ? "Paired" : "Available"
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.onSurfaceVar
                        }
                    }
                    Button {
                        text: devRow.modelData.connected ? "Disconnect" : "Connect"
                        onClicked: devRow.modelData.connected
                            ? BluetoothService.disconnectDevice(devRow.modelData)
                            : BluetoothService.connectDevice(devRow.modelData)
                    }
                }

                MouseArea {
                    id: devMa
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }
            }
        }

        Button {
            text: "Advanced (blueman)…"
            onClicked: Quickshell.execDetached(["blueman-manager"])
        }

        Item { Layout.preferredHeight: Theme.spaceXl }
    }
}
