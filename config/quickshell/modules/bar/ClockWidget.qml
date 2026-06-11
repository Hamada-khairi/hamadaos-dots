// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Clock (bar, center)
// ═══════════════════════════════════════════════════════════════════════════════
// Uses Quickshell's SystemClock (wakes exactly on the minute, cheaper than a
// 1s timer). Respects Config.options.timeFormat. Click opens the calendar app.
// ═══════════════════════════════════════════════════════════════════════════════

import QtQuick
import Quickshell
import qs
import qs.modules.common

Item {
    id: root
    implicitHeight: 40
    implicitWidth: clockLabel.implicitWidth + Theme.spaceMd * 2

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusMd
        color: ma.containsMouse ? Theme.primaryGlow : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    }

    Text {
        id: clockLabel
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date,
            Config.options.timeFormat === "12h" ? "ddd d MMM   h:mm AP" : "ddd d MMM   HH:mm")
        font.family: Theme.fontSans
        font.pixelSize: Theme.fontSizeMd
        font.weight: Font.Medium
        color: Theme.onSurface
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["sh", "-c",
            "gnome-calendar 2>/dev/null || merkuro-calendar 2>/dev/null || notify-send -a HamadaOS 'No calendar app' 'Install gnome-calendar'"])
    }
}
