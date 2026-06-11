// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Media Player (native MPRIS bindings)
// ═══════════════════════════════════════════════════════════════════════════════
// Quickshell.Services.Mpris — live metadata, album art, and position with
// zero polling and zero playerctl. Picks the playing player, else the first.
// ═══════════════════════════════════════════════════════════════════════════════

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs

Item {
    id: root

    readonly property MprisPlayer player:
        Mpris.players.values.find(p => p.isPlaying)
        ?? Mpris.players.values[0]
        ?? null
    readonly property bool hasPlayer: player !== null

    implicitHeight: 104

    // Keep the position property updated while we're showing it.
    Timer {
        interval: 1000
        running: root.hasPlayer && root.visible && (root.player?.isPlaying ?? false)
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spaceXs

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceMd

            // ── Album art (rounded via ClippingRectangle, no shader effects) ─
            ClippingRectangle {
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64
                radius: Theme.radiusMd
                color: Theme.surface2

                Text {
                    anchors.centerIn: parent
                    visible: !artImage.visible
                    text: "󰝚"
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.iconXl
                    color: Theme.onSurfaceVar
                }

                Image {
                    id: artImage
                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                    asynchronous: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: root.hasPlayer ? (root.player.trackTitle || "Unknown title") : "Nothing playing"
                    font.family: Theme.fontSans
                    font.pixelSize: Theme.fontSizeSm
                    font.weight: Font.Medium
                    color: Theme.onSurface
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: root.hasPlayer ? (root.player.trackArtist || root.player.identity) : "Play something to control it here"
                    font.family: Theme.fontSans
                    font.pixelSize: Theme.fontSizeXs
                    color: Theme.onSurfaceVar
                    elide: Text.ElideRight
                }

                // ── Controls ─────────────────────────────────────────────────
                RowLayout {
                    Layout.topMargin: Theme.spaceXs
                    spacing: Theme.spaceSm

                    MediaButton {
                        icon: "󰒮"
                        enabled: root.player?.canGoPrevious ?? false
                        onClicked: root.player.previous()
                    }
                    MediaButton {
                        icon: root.player?.isPlaying ? "󰏤" : "󰐊"
                        accent: true
                        enabled: root.player?.canTogglePlaying ?? false
                        onClicked: root.player.togglePlaying()
                    }
                    MediaButton {
                        icon: "󰒭"
                        enabled: root.player?.canGoNext ?? false
                        onClicked: root.player.next()
                    }
                }
            }
        }

        // ── Progress ─────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 3
            radius: 1.5
            color: Theme.surface2
            visible: root.hasPlayer && (root.player?.length ?? 0) > 0

            Rectangle {
                height: parent.height
                radius: 1.5
                color: Theme.primary
                width: parent.width * Math.min(1,
                    (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1))
                Behavior on width { NumberAnimation { duration: 300 } }
            }
        }
    }

    component MediaButton: Rectangle {
        property string icon: ""
        property bool accent: false
        signal clicked()

        implicitWidth: accent ? 34 : 28
        implicitHeight: accent ? 34 : 28
        radius: Theme.radiusFull
        color: accent ? Theme.primary
             : mbMa.containsMouse ? Theme.primaryGlow : "transparent"
        opacity: enabled ? 1.0 : Theme.opacityDisabled

        Text {
            anchors.centerIn: parent
            text: parent.icon
            font.family: Theme.fontMono
            font.pixelSize: parent.accent ? Theme.iconLg : Theme.iconMd
            color: parent.accent ? Theme.onPrimary : Theme.onSurface
        }

        MouseArea {
            id: mbMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (parent.enabled) parent.clicked()
        }
    }
}
