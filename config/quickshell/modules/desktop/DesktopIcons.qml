// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Desktop Icons
// ═══════════════════════════════════════════════════════════════════════════════
// Windows-style desktop: ~/Desktop rendered as an icon grid on a background
// layer (below all windows, above the wallpaper). Double-click opens with the
// default app; .desktop launchers run directly. Right-click opens the folder.
//
// No external tool needed — the PRD's "nwg-desktop" doesn't exist as a
// package; this native module is themed by the wallpaper like everything else.
// ═══════════════════════════════════════════════════════════════════════════════

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import qs
import qs.modules.common

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: desktopLayer
        required property var modelData
        screen: modelData

        WlrLayershell.namespace: "quickshell:desktop"
        WlrLayershell.layer: WlrLayer.Bottom
        exclusiveZone: 0
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        margins { top: 48; left: 12; bottom: 12 }

        FolderListModel {
            id: desktopFolder
            folder: "file://" + Quickshell.env("HOME") + "/Desktop"
            showDirsFirst: true
            showDotAndDotDot: false
            showHidden: false
        }

        GridView {
            anchors.fill: parent
            cellWidth: 96
            cellHeight: 100
            flow: GridView.FlowTopToBottom   // Windows fills columns first
            interactive: false
            model: desktopFolder

            delegate: Item {
                id: iconItem
                required property string fileName
                required property string filePath
                required property bool fileIsDir

                width: 90
                height: 94

                readonly property bool isLauncher: fileName.endsWith(".desktop")
                readonly property var entry: isLauncher
                    ? DesktopEntries.applications.values.find(e =>
                          filePath.endsWith("/" + e.id + ".desktop")
                          || e.id === fileName.replace(/\.desktop$/, ""))
                      ?? DesktopEntries.heuristicLookup(fileName.replace(/\.desktop$/, ""))
                    : null

                function open() {
                    if (entry) entry.execute()
                    else Quickshell.execDetached(["xdg-open", filePath])
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusSm
                    color: iconMa.containsMouse
                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18)
                        : "transparent"
                    border {
                        width: iconMa.containsMouse ? 1 : 0
                        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4)
                    }
                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                }

                Column {
                    anchors { top: parent.top; topMargin: 8; horizontalCenter: parent.horizontalCenter }
                    spacing: 4

                    IconImage {
                        anchors.horizontalCenter: parent.horizontalCenter
                        implicitSize: 44
                        source: {
                            if (iconItem.entry)
                                return Quickshell.iconPath(iconItem.entry.icon, "application-x-executable")
                            if (iconItem.fileIsDir)
                                return Quickshell.iconPath("folder")
                            const n = iconItem.fileName.toLowerCase()
                            if (/\.(png|jpe?g|webp|gif|svg)$/.test(n)) return Quickshell.iconPath("image-x-generic")
                            if (/\.(mp4|mkv|webm|avi)$/.test(n)) return Quickshell.iconPath("video-x-generic")
                            if (/\.(mp3|flac|ogg|wav)$/.test(n)) return Quickshell.iconPath("audio-x-generic")
                            if (/\.(pdf)$/.test(n)) return Quickshell.iconPath("application-pdf")
                            if (/\.(zip|tar|gz|7z|rar)$/.test(n)) return Quickshell.iconPath("package-x-generic")
                            return Quickshell.iconPath("text-x-generic")
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 84
                        text: iconItem.entry?.name
                            ?? iconItem.fileName.replace(/\.desktop$/, "")
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fontSizeXs
                        color: "white"
                        style: Text.Outline
                        styleColor: Qt.rgba(0, 0, 0, 0.8)
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: iconMa
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onDoubleClicked: iconItem.open()
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton)
                            Quickshell.execDetached(["dolphin", "--select", iconItem.filePath])
                    }
                }
            }
        }
    }
}
