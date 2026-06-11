// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Status Icons (bar, right side)
// ═══════════════════════════════════════════════════════════════════════════════
// Network (live nmcli events) · Battery (UPower, laptops only) ·
// Volume (PipeWire, scroll to adjust) · Keyboard layout · Settings gear ·
// Control Center toggle. Everything is event-driven — no /tmp files.
// ═══════════════════════════════════════════════════════════════════════════════

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Hyprland
import qs
import qs.modules.common
import qs.modules.services

RowLayout {
    id: root
    spacing: Theme.spaceXs

    component BarButton: Rectangle {
        id: btn
        property string icon: ""
        property color iconColor: Theme.onSurface
        signal clicked()
        signal scrolledUp()
        signal scrolledDown()

        width: 30; height: 30
        radius: Theme.radiusFull
        color: btnMa.containsMouse ? Theme.primaryGlow : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.durationFast } }

        Text {
            anchors.centerIn: parent
            text: btn.icon
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSizeLg
            color: btn.iconColor
        }

        MouseArea {
            id: btnMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
            onWheel: wheel => wheel.angleDelta.y > 0 ? btn.scrolledUp() : btn.scrolledDown()
        }
    }

    // ── Keyboard layout (appears after the first layout switch) ────────────
    Text {
        id: layoutLabel
        visible: text !== ""
        text: ""
        font.family: Theme.fontSans
        font.pixelSize: Theme.fontSizeXs
        font.weight: Font.Bold
        color: Theme.onSurfaceVar

        Connections {
            target: Hyprland
            function onRawEvent(event) {
                if (event.name !== "activelayout") return
                const layout = event.data.split(",").pop() ?? ""
                layoutLabel.text = layout.includes("Arabic") ? "AR"
                    : layout.toLowerCase().includes("english") ? "EN"
                    : layout.slice(0, 2).toUpperCase()
            }
        }
    }

    // ── Network ─────────────────────────────────────────────────────────────
    BarButton {
        icon: NetworkService.materialIcon
        iconColor: NetworkService.connected ? Theme.onSurface : Theme.colorWarning
        onClicked: { GlobalStates.settingsOpen = true }
    }

    // ── Battery (hidden on desktops) ────────────────────────────────────────
    BarButton {
        visible: UPower.displayDevice?.isLaptopBattery ?? false
        readonly property real pct: (UPower.displayDevice?.percentage ?? 1) * 100
        readonly property bool charging:
            UPower.displayDevice?.state === UPowerDeviceState.Charging
        icon: {
            if (charging) return "󰂄"
            if (pct >= 90) return "󰁹"
            if (pct >= 70) return "󰂁"
            if (pct >= 40) return "󰁾"
            if (pct >= 20) return "󰁼"
            return "󰁺"
        }
        iconColor: pct <= 15 && !charging ? Theme.error : Theme.onSurface
        onClicked: Quickshell.execDetached([
            "notify-send", "-a", "HamadaOS", "Battery",
            Math.round(pct) + "%" + (charging ? " — charging" : "")
        ])
    }

    // ── Volume (click = mute, scroll = adjust) ──────────────────────────────
    BarButton {
        icon: {
            if (AudioService.muted) return "󰸈"
            if (AudioService.volume > 0.66) return "󰕾"
            if (AudioService.volume > 0.33) return "󰖀"
            if (AudioService.volume > 0) return "󰕿"
            return "󰸈"
        }
        onClicked: AudioService.toggleMute()
        onScrolledUp: AudioService.increment()
        onScrolledDown: AudioService.decrement()
    }

    // ── Notifications (unread badge) ────────────────────────────────────────
    BarButton {
        icon: Config.options.doNotDisturb ? "󰂛" : "󰂚"
        iconColor: NotificationService.unread > 0 ? Theme.primary : Theme.onSurface
        onClicked: {
            Config.options.doNotDisturb = !Config.options.doNotDisturb
            NotificationService.unread = 0
        }
    }

    // ── Settings ────────────────────────────────────────────────────────────
    BarButton {
        icon: "󰒓"
        onClicked: GlobalStates.settingsOpen = true
    }

    // ── Control Center ──────────────────────────────────────────────────────
    BarButton {
        icon: "󰍜"
        iconColor: GlobalStates.controlCenterOpen ? Theme.primary : Theme.onSurface
        onClicked: GlobalStates.controlCenterOpen = !GlobalStates.controlCenterOpen
    }
}
