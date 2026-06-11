// HamadaOS Settings — Network (NetworkService + inline password dialog)
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

    property string pendingSsid: ""   // network awaiting a password

    Component.onCompleted: NetworkService.rescan()

    ColumnLayout {
        id: col
        width: root.width
        spacing: Theme.spaceLg

        SectionTitle { text: "WiFi" }

        ToggleRow {
            label: "WiFi"
            description: NetworkService.connected
                ? "Connected to " + (NetworkService.activeSsid || NetworkService.connectionType)
                : "Not connected"
            checked: NetworkService.wifiEnabled
            onToggled: NetworkService.toggleWifi()
        }

        RowLayout {
            Text { text: "Available networks"; font.pixelSize: Theme.fontSizeSm; color: Theme.onSurfaceVar; Layout.fillWidth: true }
            Button {
                text: NetworkService.scanning ? "Scanning…" : "Rescan"
                enabled: !NetworkService.scanning
                onClicked: NetworkService.rescan()
            }
        }

        Repeater {
            model: NetworkService.networks

            ColumnLayout {
                id: netItem
                required property var modelData
                Layout.fillWidth: true
                spacing: Theme.spaceXs

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 42
                    radius: Theme.radiusSm
                    color: netMa.containsMouse ? Theme.primaryGlow : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                    RowLayout {
                        anchors { fill: parent; leftMargin: Theme.spaceSm; rightMargin: Theme.spaceSm }
                        spacing: Theme.spaceMd

                        Text {
                            text: netItem.modelData.signal >= 75 ? "󰤨"
                                : netItem.modelData.signal >= 50 ? "󰤥"
                                : netItem.modelData.signal >= 25 ? "󰤢" : "󰤟"
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.iconMd
                            color: netItem.modelData.inUse ? Theme.primary : Theme.onSurface
                        }
                        Text {
                            Layout.fillWidth: true
                            text: netItem.modelData.ssid
                            font.pixelSize: Theme.fontSizeSm
                            font.weight: netItem.modelData.inUse ? Font.Bold : Font.Normal
                            color: Theme.onSurface
                            elide: Text.ElideRight
                        }
                        Text {
                            visible: netItem.modelData.secure
                            text: "󰌾"
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeSm
                            color: Theme.onSurfaceVar
                        }
                        Text {
                            visible: netItem.modelData.inUse
                            text: "connected"
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.primary
                        }
                    }

                    MouseArea {
                        id: netMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (netItem.modelData.inUse) return
                            if (netItem.modelData.secure) {
                                root.pendingSsid = root.pendingSsid === netItem.modelData.ssid
                                    ? "" : netItem.modelData.ssid
                            } else {
                                NetworkService.connect(netItem.modelData.ssid, "")
                            }
                        }
                    }
                }

                // ── Inline password entry for secured networks ───────────────
                RowLayout {
                    visible: root.pendingSsid === netItem.modelData.ssid
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.spaceXl
                    spacing: Theme.spaceSm

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: Theme.radiusSm
                        color: Theme.surface2
                        border { width: 1; color: pwInput.activeFocus ? Theme.primary : Theme.outline }

                        TextInput {
                            id: pwInput
                            anchors { fill: parent; leftMargin: Theme.spaceSm; rightMargin: Theme.spaceSm }
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            font.pixelSize: Theme.fontSizeSm
                            color: Theme.onSurface
                            clip: true
                            Keys.onReturnPressed: {
                                NetworkService.connect(netItem.modelData.ssid, text)
                                root.pendingSsid = ""
                            }
                            Text {
                                anchors.fill: parent
                                visible: pwInput.text === ""
                                text: "Password"
                                font.pixelSize: Theme.fontSizeSm
                                color: Theme.onSurfaceVar
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                    Button {
                        text: "Connect"
                        onClicked: {
                            NetworkService.connect(netItem.modelData.ssid, pwInput.text)
                            root.pendingSsid = ""
                        }
                    }
                }
            }
        }

        SectionTitle { text: "VPN & advanced" }

        RowLayout {
            spacing: Theme.spaceMd
            Button { text: "Connection editor…"; onClicked: Quickshell.execDetached(["nm-connection-editor"]) }
        }

        Item { Layout.preferredHeight: Theme.spaceXl }
    }
}
