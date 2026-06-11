// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Notification Popups
// ═══════════════════════════════════════════════════════════════════════════════
// Renders NotificationService.popupList as animated banners (top-right).
// Spring slide-in, click body to dismiss, action buttons invoke for real.
// ═══════════════════════════════════════════════════════════════════════════════

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.modules.common
import qs.modules.services

PanelWindow {
    id: win
    WlrLayershell.namespace: "quickshell:notificationPopup"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusiveZone: 0
    color: "transparent"
    anchors { top: true; right: true }
    margins { top: 48; right: 8 }

    implicitWidth: 380
    implicitHeight: Math.min(notifColumn.implicitHeight + 16, 600)
    visible: NotificationService.popupList.length > 0

    ColumnLayout {
        id: notifColumn
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 8 }
        spacing: Theme.spaceSm

        Repeater {
            model: NotificationService.popupList

            Rectangle {
                id: banner
                required property var modelData

                Layout.fillWidth: true
                implicitHeight: bannerContent.implicitHeight + Theme.spaceMd * 2
                radius: Theme.radiusLg
                color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b,
                               Theme.opacityPopup)
                border {
                    width: 1
                    color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.35)
                }

                // Spring in from the right.
                transform: Translate {
                    id: slide
                    x: 400
                    Component.onCompleted: x = 0
                    Behavior on x {
                        SpringAnimation { spring: 3.5; damping: 0.78; epsilon: 0.5 }
                    }
                }

                ColumnLayout {
                    id: bannerContent
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceMd }
                    spacing: Theme.spaceSm

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spaceMd

                        // App icon or image
                        ClippingRectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            radius: Theme.radiusSm
                            color: Theme.surface2

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 24
                                visible: banner.modelData.image === "" && banner.modelData.appIcon !== ""
                                source: banner.modelData.appIcon !== ""
                                    ? Quickshell.iconPath(banner.modelData.appIcon, "dialog-information")
                                    : ""
                            }
                            Image {
                                anchors.fill: parent
                                visible: banner.modelData.image !== ""
                                source: banner.modelData.image
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: banner.modelData.image === "" && banner.modelData.appIcon === ""
                                text: "󰂚"
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.iconMd
                                color: Theme.primary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    Layout.fillWidth: true
                                    text: banner.modelData.summary
                                    font.family: Theme.fontSans
                                    font.pixelSize: Theme.fontSizeSm
                                    font.weight: Font.Bold
                                    color: Theme.onSurface
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: banner.modelData.appName
                                    font.pixelSize: Theme.fontSizeXs
                                    color: Theme.onSurfaceVar
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: banner.modelData.body
                                textFormat: Text.StyledText
                                font.family: Theme.fontSans
                                font.pixelSize: Theme.fontSizeXs
                                color: Theme.onSurfaceVar
                                wrapMode: Text.WordWrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                            }
                        }
                    }

                    // ── Action buttons ───────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spaceSm
                        visible: banner.modelData.actions.length > 0

                        Repeater {
                            model: banner.modelData.actions

                            Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 28
                                radius: Theme.radiusSm
                                color: actionMa.containsMouse ? Theme.primaryGlow : Theme.surface2

                                Text {
                                    anchors.centerIn: parent
                                    text: parent.modelData.text
                                    font.pixelSize: Theme.fontSizeXs
                                    color: Theme.primary
                                }
                                MouseArea {
                                    id: actionMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NotificationService.invokeAction(
                                        banner.modelData.notifId,
                                        parent.modelData.identifier)
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: NotificationService.discard(banner.modelData.notifId)
                }
            }
        }
    }
}
