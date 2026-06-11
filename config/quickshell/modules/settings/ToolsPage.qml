// HamadaOS Settings — Tools (Windows' Administrative Tools, centralized)
// Disks, logs, services, device info, startup apps, network tools, backup,
// rescue — plus a controller center with live battery from UPower.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.modules.common

Flickable {
    id: root
    contentHeight: col.implicitHeight
    clip: true

    component ToolButton: Rectangle {
        property string icon: ""
        property string label: ""
        property string sub: ""
        property var command: []

        Layout.fillWidth: true
        implicitHeight: 76
        radius: Theme.radiusMd
        color: tbMa.containsMouse ? Theme.primaryGlow : Theme.surface2
        Behavior on color { ColorAnimation { duration: Theme.durationFast } }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: parent.parent.icon
                font.family: Theme.fontMono
                font.pixelSize: Theme.iconLg
                color: Theme.primary
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: parent.parent.label
                font.pixelSize: Theme.fontSizeSm
                font.weight: Font.Medium
                color: Theme.onSurface
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: text !== ""
                text: parent.parent.sub
                font.pixelSize: Theme.fontSizeXs
                color: Theme.onSurfaceVar
            }
        }
        MouseArea {
            id: tbMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Quickshell.execDetached(parent.command)
        }
    }

    ColumnLayout {
        id: col
        width: root.width
        spacing: Theme.spaceLg

        SectionTitle { text: "Controllers" }

        // Gaming input devices with batteries (DualSense/Xbox over BT)
        Repeater {
            model: [...(UPower.devices?.values ?? [])].filter(d =>
                d.isLaptopBattery === false && (d.percentage ?? -1) >= 0
                && d.model !== "" && !d.powerSupply)

            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: Theme.spaceMd
                Text { text: "󰊴"; font.family: Theme.fontMono; font.pixelSize: Theme.iconMd; color: Theme.primary }
                Text {
                    Layout.fillWidth: true
                    text: parent.modelData.model
                    font.pixelSize: Theme.fontSizeSm
                    color: Theme.onSurface
                    elide: Text.ElideRight
                }
                Text {
                    text: Math.round((parent.modelData.percentage ?? 0) * 100) + "%"
                    font.pixelSize: Theme.fontSizeSm
                    font.weight: Font.Bold
                    color: (parent.modelData.percentage ?? 0) < 0.2 ? Theme.colorWarning : Theme.colorSuccess
                }
            }
        }
        Text {
            visible: [...(UPower.devices?.values ?? [])].filter(d =>
                d.isLaptopBattery === false && (d.percentage ?? -1) >= 0
                && d.model !== "" && !d.powerSupply).length === 0
            text: "No wireless controller connected. Xbox/DualSense pair via Settings → Bluetooth — buttons, paddles, and gyro work out of the box (game-devices-udev rules ship with HamadaOS)."
            font.pixelSize: Theme.fontSizeXs
            color: Theme.onSurfaceVar
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        RowLayout {
            spacing: Theme.spaceMd
            Button {
                text: "Remap buttons (Steam)"
                onClicked: Quickshell.execDetached(["steam", "steam://open/bigpicture"])
            }
            Button {
                text: "Remap anywhere (input-remapper)"
                onClicked: Quickshell.execDetached(["input-remapper-gtk"])
            }
        }

        SectionTitle { text: "Admin tools" }

        GridLayout {
            columns: 3
            columnSpacing: Theme.spaceSm
            rowSpacing: Theme.spaceSm
            Layout.fillWidth: true

            ToolButton { icon: "󰋊"; label: "Disks"; sub: "diskmgmt"; command: ["gnome-disks"] }
            ToolButton { icon: "󰒓"; label: "Device Info"; sub: "devmgmt"; command: ["hardinfo2"] }
            ToolButton { icon: "󰈸"; label: "Task Manager"; sub: "+ startup apps"; command: ["mission-center"] }
            ToolButton { icon: "󱂬"; label: "Event Viewer"; sub: "system logs"; command: ["kitty", "--title", "System Logs", "-e", "journalctl", "-b", "-f"] }
            ToolButton { icon: "󰢻"; label: "Services"; sub: "failed units"; command: ["kitty", "--title", "Services", "-e", "sh", "-c", "systemctl --failed; echo; echo 'All units: systemctl list-units'; exec bash"] }
            ToolButton { icon: "󰛳"; label: "Network Tools"; sub: "nmtui"; command: ["kitty", "--title", "Network", "-e", "nmtui"] }
            ToolButton { icon: "󰐪"; label: "Printers"; command: ["system-config-printer"] }
            ToolButton { icon: "󰁯"; label: "Snapshots"; sub: "system restore"; command: ["snapper-gui"] }
            ToolButton { icon: "󰍛"; label: "GPU Control"; sub: "LACT"; command: ["lact"] }
        }

        SectionTitle { text: "Backup & recovery" }

        RowLayout {
            spacing: Theme.spaceMd
            Button {
                text: "Export my settings"
                onClicked: Quickshell.execDetached(["sh", "-c",
                    "~/.config/hypr/scripts/hamadaos-backup.sh export"])
            }
            Button {
                text: "Import settings…"
                onClicked: Quickshell.execDetached(["sh", "-c",
                    "f=$(zenity --file-selection --title='Import HamadaOS backup' --file-filter='*.tar.gz' 2>/dev/null); " +
                    "[ -n \"$f\" ] && kitty --title 'Import settings' -e ~/.config/hypr/scripts/hamadaos-backup.sh import \"$f\""])
            }
            Button {
                text: "Rescue menu"
                onClicked: Quickshell.execDetached(["kitty", "--title", "HamadaOS Rescue",
                    "-e", "sh", "-c", "~/.config/hypr/scripts/hamadaos-rescue.sh"])
            }
        }
        Text {
            Layout.fillWidth: true
            text: "If the desktop ever fails to start: pick \"HamadaOS (Safe Mode)\" at the login screen — minimal session, always boots, opens this rescue menu automatically."
            font.pixelSize: Theme.fontSizeXs
            color: Theme.onSurfaceVar
            wrapMode: Text.WordWrap
        }

        Item { Layout.preferredHeight: Theme.spaceXl }
    }
}
