// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — On-Screen Display (volume / brightness)
// ═══════════════════════════════════════════════════════════════════════════════
// Hardware keys are bound to AudioService/BrightnessService via the IPC
// handler below (keybindings.conf calls `qs ipc call osd ...`), so the
// change and the popup always agree. Flashes for 1.2s, springs in from
// the bottom, no input — pure feedback.
// ═══════════════════════════════════════════════════════════════════════════════

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.modules.services

Scope {
    id: root

    property string mode: "volume"   // "volume" | "brightness"
    property bool shown: false

    Timer {
        id: hideTimer
        interval: 1200
        onTriggered: root.shown = false
    }

    function flash(which) {
        mode = which
        shown = true
        hideTimer.restart()
    }

    // External volume changes (hardware keys, other apps) flash the OSD too.
    Connections {
        target: AudioService
        function onVolumeChangedByUser() { root.flash("volume") }
    }
    Connections {
        target: BrightnessService
        function onBrightnessChangedByUser() { root.flash("brightness") }
    }

    // Bound in keybindings.conf:  qs ipc call osd volumeUp  etc.
    IpcHandler {
        target: "osd"
        function volumeUp(): void     { AudioService.increment() }
        function volumeDown(): void   { AudioService.decrement() }
        function volumeMute(): void   { AudioService.toggleMute() }
        function micMute(): void      { AudioService.toggleMicMute() }
        function brightnessUp(): void   { BrightnessService.increment() }
        function brightnessDown(): void { BrightnessService.decrement() }
    }

    LazyLoader {
        active: root.shown

        PanelWindow {
            WlrLayershell.namespace: "quickshell:osd"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusiveZone: 0
            color: "transparent"
            anchors { bottom: true }
            margins { bottom: 96 }
            implicitWidth: 280
            implicitHeight: 64

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusXl
                color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b,
                               Theme.opacityPopup)
                border { width: 1; color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.35) }

                RowLayout {
                    anchors { fill: parent; leftMargin: Theme.spaceLg; rightMargin: Theme.spaceLg }
                    spacing: Theme.spaceMd

                    Text {
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.iconLg
                        color: Theme.primary
                        text: {
                            if (root.mode === "brightness") return "󰃟"
                            if (AudioService.muted) return "󰸈"
                            if (AudioService.volume > 0.66) return "󰕾"
                            if (AudioService.volume > 0.33) return "󰖀"
                            return "󰕿"
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 6
                        radius: 3
                        color: Theme.surface2

                        Rectangle {
                            height: parent.height
                            radius: 3
                            color: AudioService.muted && root.mode === "volume"
                                ? Theme.onSurfaceVar : Theme.primary
                            width: parent.width * (root.mode === "volume"
                                ? Math.min(1, AudioService.volume)
                                : Math.max(0, BrightnessService.brightness))
                            Behavior on width {
                                SpringAnimation { spring: 4.5; damping: 0.85; epsilon: 0.5 }
                            }
                        }
                    }

                    Text {
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.Bold
                        color: Theme.onSurface
                        Layout.preferredWidth: 40
                        horizontalAlignment: Text.AlignRight
                        text: root.mode === "volume"
                            ? (AudioService.muted ? "muted" : Math.round(AudioService.volume * 100) + "%")
                            : Math.round(Math.max(0, BrightnessService.brightness) * 100) + "%"
                    }
                }
            }
        }
    }
}
