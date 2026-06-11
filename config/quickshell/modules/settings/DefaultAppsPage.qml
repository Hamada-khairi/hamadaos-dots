// HamadaOS Settings — Default Apps (Windows "Default apps" equivalent)
// Pick your browser, file manager, media players — applies system-wide
// through XDG, so every app and file picker respects it.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.modules.common
import qs.modules.services

Flickable {
    id: root
    contentHeight: col.implicitHeight
    clip: true

    Component.onCompleted: DefaultAppsService.refresh()

    ColumnLayout {
        id: col
        width: root.width
        spacing: Theme.spaceMd

        SectionTitle { text: "Default apps" }

        Text {
            Layout.fillWidth: true
            text: "These apply system-wide (XDG) — links, folders, and files open with what you pick here."
            font.pixelSize: Theme.fontSizeSm
            color: Theme.onSurfaceVar
            wrapMode: Text.WordWrap
        }

        Repeater {
            model: Object.keys(DefaultAppsService.roles)

            Rectangle {
                id: roleRow
                required property string modelData

                readonly property var role: DefaultAppsService.roles[modelData]
                readonly property list<var> candidates: DefaultAppsService.candidatesFor(modelData)
                readonly property string currentId: DefaultAppsService.current[modelData] ?? ""

                Layout.fillWidth: true
                implicitHeight: 56
                radius: Theme.radiusMd
                color: Theme.surface2

                RowLayout {
                    anchors { fill: parent; leftMargin: Theme.spaceMd; rightMargin: Theme.spaceMd }
                    spacing: Theme.spaceMd

                    Text {
                        text: roleRow.role.icon
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.iconMd
                        color: Theme.primary
                        Layout.preferredWidth: 26
                    }

                    Text {
                        text: roleRow.role.label
                        font.pixelSize: Theme.fontSizeMd
                        color: Theme.onSurface
                        Layout.preferredWidth: 130
                    }

                    Item { Layout.fillWidth: true }

                    // Current default's icon, next to the picker.
                    IconImage {
                        implicitSize: 22
                        visible: source !== ""
                        source: {
                            const entry = [...DesktopEntries.applications.values].find(e =>
                                roleRow.currentId === e.id + ".desktop" || roleRow.currentId === e.id)
                            return entry ? Quickshell.iconPath(entry.icon, "application-x-executable") : ""
                        }
                    }

                    ComboBox {
                        Layout.preferredWidth: 240
                        model: roleRow.candidates.map(e => e.name)
                        currentIndex: roleRow.candidates.findIndex(e =>
                            roleRow.currentId === e.id + ".desktop" || roleRow.currentId === e.id)
                        displayText: currentIndex >= 0 ? currentText
                            : (roleRow.currentId !== "" ? roleRow.currentId.replace(".desktop", "") : "Not set")
                        onActivated: index =>
                            DefaultAppsService.setDefault(roleRow.modelData, roleRow.candidates[index].id)
                    }
                }
            }
        }

        Item { Layout.preferredHeight: Theme.spaceXl }
    }
}
