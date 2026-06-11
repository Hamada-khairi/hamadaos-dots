// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — First-Run Welcome
// ═══════════════════════════════════════════════════════════════════════════════
// Opens once on first login. Pick your apps (installed on the spot), learn
// the three keybinds that matter, done. Closing it marks first-run complete.
// ═══════════════════════════════════════════════════════════════════════════════

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common

FloatingWindow {
    id: welcome
    title: "Welcome to HamadaOS"
    implicitWidth: 640
    implicitHeight: 560
    color: Theme.surface

    visible: true
    onVisibleChanged: if (!visible) Config.options.firstRunDone = true

    // App suite candidates: { name, pkg, desc, checked-by-default }
    property var appChoices: [
        { name: "Firefox",        pkg: "firefox",            desc: "Web browser", on: true },
        { name: "LibreOffice",    pkg: "libreoffice-fresh",  desc: "Office suite (Word/Excel equivalent)", on: true },
        { name: "VLC",            pkg: "vlc",                desc: "Plays every video format", on: true },
        { name: "Thunderbird",    pkg: "thunderbird",        desc: "Email + calendar", on: false },
        { name: "Vesktop",        pkg: "vesktop",            desc: "Discord with working screenshare", on: true },
        { name: "Telegram",       pkg: "telegram-desktop",   desc: "Messaging", on: false },
        { name: "OBS Studio",     pkg: "obs-studio",         desc: "Recording & streaming", on: false },
        { name: "GIMP",           pkg: "gimp",               desc: "Image editor (Photoshop equivalent)", on: false }
    ]
    property var selected: appChoices.filter(a => a.on).map(a => a.pkg)

    ColumnLayout {
        anchors { fill: parent; margins: Theme.space2xl }
        spacing: Theme.spaceLg

        Text {
            text: "Welcome to HamadaOS 👋"
            font.family: Theme.fontDisplay
            font.pixelSize: Theme.fontSize2xl
            font.weight: Font.Bold
            color: Theme.primary
        }
        Text {
            Layout.fillWidth: true
            text: "Pick your apps — they install in the background. Everything is changeable later in Settings → Default Apps."
            font.pixelSize: Theme.fontSizeSm
            color: Theme.onSurfaceVar
            wrapMode: Text.WordWrap
        }

        // ── App picker ───────────────────────────────────────────────────────
        GridLayout {
            columns: 2
            columnSpacing: Theme.spaceSm
            rowSpacing: Theme.spaceSm
            Layout.fillWidth: true

            Repeater {
                model: welcome.appChoices

                Rectangle {
                    id: appCard
                    required property var modelData
                    required property int index
                    property bool checked: modelData.on

                    Layout.fillWidth: true
                    implicitHeight: 56
                    radius: Theme.radiusMd
                    color: checked ? Theme.primaryGlow : Theme.surface2
                    border { width: 1; color: appCard.checked ? Theme.primary : "transparent" }
                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                    RowLayout {
                        anchors { fill: parent; leftMargin: Theme.spaceMd; rightMargin: Theme.spaceMd }
                        spacing: Theme.spaceMd
                        Text {
                            text: appCard.checked ? "󰄬" : "󰄱"
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.iconMd
                            color: appCard.checked ? Theme.primary : Theme.onSurfaceVar
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text { text: appCard.modelData.name; font.pixelSize: Theme.fontSizeSm; font.weight: Font.Medium; color: Theme.onSurface }
                            Text { text: appCard.modelData.desc; font.pixelSize: Theme.fontSizeXs; color: Theme.onSurfaceVar; elide: Text.ElideRight; Layout.fillWidth: true }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            appCard.checked = !appCard.checked
                            welcome.selected = appCard.checked
                                ? [...welcome.selected, appCard.modelData.pkg]
                                : welcome.selected.filter(p => p !== appCard.modelData.pkg)
                        }
                    }
                }
            }
        }

        // ── The three keybinds that matter ───────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            radius: Theme.radiusMd
            color: Theme.surface2
            implicitHeight: keysCol.implicitHeight + Theme.spaceMd * 2
            ColumnLayout {
                id: keysCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceMd }
                spacing: 4
                component KeyHint: Text { font.pixelSize: Theme.fontSizeXs; color: Theme.onSurfaceVar }
                KeyHint { text: "⊞ Super + Space — search apps (try typing \"control panel\")" }
                KeyHint { text: "⊞ Super + I — Settings    ·    Ctrl+Shift+Esc — Task Manager" }
                KeyHint { text: "⊞ Super + Shift + G — Gaming Mode    ·    Ctrl+Alt+1 — ZoomIt" }
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            Button {
                text: "Skip"
                onClicked: { Config.options.firstRunDone = true; welcome.visible = false }
            }
            Item { Layout.fillWidth: true }
            Button {
                text: welcome.selected.length > 0
                    ? "Install " + welcome.selected.length + " app(s) & finish"
                    : "Finish"
                onClicked: {
                    if (welcome.selected.length > 0) {
                        Quickshell.execDetached(["kitty", "--title", "Installing your apps",
                            "-e", "sh", "-c",
                            "yay -S --needed --noconfirm " + welcome.selected.join(" ")
                            + " || paru -S --needed --noconfirm " + welcome.selected.join(" ")
                            + "; echo; echo Done.; read -r"])
                    }
                    Config.options.firstRunDone = true
                    welcome.visible = false
                }
            }
        }
    }
}
