// HamadaOS Settings — Health (the "check everything and let me go play" page)
// One click runs the full doctor; one click fixes what's fixable; updates
// from CachyOS repos, AUR, HyDE, and hamadaos-dots show in one place.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common

Flickable {
    id: root
    contentHeight: col.implicitHeight
    clip: true

    property var checks: []
    property int passCount: 0
    property int warnCount: 0
    property int failCount: 0
    property int fixedCount: 0
    property bool running: false
    property bool hasRun: false
    property var updates: ({ repo: 0, aur: 0, dots: 0, hyde: 0, total: 0 })

    Component.onCompleted: {
        runDoctor(false)
        updateCheck.running = true
    }

    function runDoctor(fix) {
        if (running) return
        running = true
        checks = []
        doctorProc.command = ["bash",
            Quickshell.env("HOME") + "/.config/hypr/scripts/hamadaos-doctor.sh",
            fix ? "--fix" : "--json"]
        if (fix) doctorProc.command = ["bash", "-c",
            "~/.config/hypr/scripts/hamadaos-doctor.sh --fix >/dev/null 2>&1; " +
            "~/.config/hypr/scripts/hamadaos-doctor.sh --json"]
        doctorProc.running = true
    }

    Process {
        id: doctorProc
        stdout: StdioCollector {
            onStreamFinished: {
                const list = []
                let p = 0, w = 0, f = 0, fx = 0
                for (const line of text.trim().split("\n")) {
                    try {
                        const o = JSON.parse(line)
                        if (o.summary) { p = o.pass; w = o.warn; f = o.fail; fx = o.fixed }
                        else list.push(o)
                    } catch (e) { }
                }
                root.checks = list
                root.passCount = p; root.warnCount = w
                root.failCount = f; root.fixedCount = fx
                root.running = false
                root.hasRun = true
            }
        }
    }

    Process {
        id: updateCheck
        command: ["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/hamadaos-update.sh", "--check"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.updates = JSON.parse(text.trim()) } catch (e) { }
            }
        }
    }

    ColumnLayout {
        id: col
        width: root.width
        spacing: Theme.spaceLg

        // ═══ Status hero card ═══════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 96
            radius: Theme.radiusLg
            color: !root.hasRun ? Theme.surface2
                 : root.failCount > 0 ? Qt.rgba(Theme.colorDanger.r, Theme.colorDanger.g, Theme.colorDanger.b, 0.15)
                 : root.warnCount > 0 ? Qt.rgba(Theme.colorWarning.r, Theme.colorWarning.g, Theme.colorWarning.b, 0.12)
                 : Qt.rgba(Theme.colorSuccess.r, Theme.colorSuccess.g, Theme.colorSuccess.b, 0.12)
            Behavior on color { ColorAnimation { duration: Theme.durationNormal } }

            RowLayout {
                anchors { fill: parent; leftMargin: Theme.spaceLg; rightMargin: Theme.spaceLg }
                spacing: Theme.spaceLg

                Text {
                    text: root.running ? "󰔟"
                        : !root.hasRun ? "󰋗"
                        : root.failCount > 0 ? "󰀪"
                        : root.warnCount > 0 ? "󰗖" : "󰗠"
                    font.family: Theme.fontMono
                    font.pixelSize: 42
                    color: !root.hasRun ? Theme.onSurfaceVar
                         : root.failCount > 0 ? Theme.colorDanger
                         : root.warnCount > 0 ? Theme.colorWarning : Theme.colorSuccess
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: root.running ? "Checking your system…"
                            : !root.hasRun ? "System health"
                            : root.failCount > 0 ? root.failCount + " problem(s) found"
                            : root.warnCount > 0 ? "Healthy — " + root.warnCount + " optional improvement(s)"
                            : "Everything works. Go play. 🎮"
                        font.pixelSize: Theme.fontSizeLg
                        font.weight: Font.Bold
                        color: Theme.onSurface
                    }
                    Text {
                        visible: root.hasRun && !root.running
                        text: root.passCount + " checks passed"
                            + (root.fixedCount > 0 ? " · " + root.fixedCount + " auto-fixed" : "")
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.onSurfaceVar
                    }
                }

                Button {
                    text: root.running ? "…" : "Check"
                    enabled: !root.running
                    onClicked: root.runDoctor(false)
                }
                Button {
                    text: "Fix everything"
                    visible: root.failCount > 0 || root.warnCount > 0
                    enabled: !root.running
                    onClicked: root.runDoctor(true)
                }
            }
        }

        // ═══ Updates ════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 72
            radius: Theme.radiusMd
            color: Theme.surface2

            RowLayout {
                anchors { fill: parent; leftMargin: Theme.spaceLg; rightMargin: Theme.spaceLg }
                spacing: Theme.spaceLg

                Text {
                    text: root.updates.total > 0 ? "󰚰" : "󰄬"
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.iconXl
                    color: root.updates.total > 0 ? Theme.primary : Theme.colorSuccess
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: root.updates.total > 0
                            ? root.updates.total + " updates available"
                            : "Up to date"
                        font.pixelSize: Theme.fontSizeMd
                        font.weight: Font.Bold
                        color: Theme.onSurface
                    }
                    Text {
                        visible: root.updates.total > 0
                        text: "System: " + root.updates.repo + "  ·  AUR: " + root.updates.aur
                            + "  ·  HyDE: " + root.updates.hyde + "  ·  HamadaOS: " + root.updates.dots
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.onSurfaceVar
                    }
                }
                Button {
                    text: "Refresh"
                    onClicked: updateCheck.running = true
                }
                Button {
                    text: "Update everything"
                    visible: root.updates.total > 0
                    onClicked: Quickshell.execDetached(["kitty", "--title", "HamadaOS Update",
                        "-e", "bash", Quickshell.env("HOME") + "/.config/hypr/scripts/hamadaos-update.sh", "--apply"])
                }
            }
        }

        // ═══ Check results ══════════════════════════════════════════════════
        SectionTitle { text: "Details"; visible: root.checks.length > 0 }

        Repeater {
            model: root.checks

            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: Theme.spaceMd

                Rectangle {
                    width: 10; height: 10; radius: 5
                    color: parent.modelData.status === "ok" ? Theme.colorSuccess
                         : parent.modelData.status === "warn" ? Theme.colorWarning
                         : Theme.colorDanger
                }
                Text {
                    text: parent.modelData.name
                    font.pixelSize: Theme.fontSizeSm
                    color: Theme.onSurface
                    Layout.preferredWidth: 260
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: (parent.modelData.fixed ? "fixed ✓  " : "") + (parent.modelData.detail ?? "")
                    font.pixelSize: Theme.fontSizeXs
                    color: parent.modelData.fixed ? Theme.colorSuccess : Theme.onSurfaceVar
                    elide: Text.ElideRight
                }
            }
        }

        Item { Layout.preferredHeight: Theme.spaceXl }
    }
}
