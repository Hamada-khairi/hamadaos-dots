// HamadaOS Settings — App Compatibility Center
// The honest answers, with LIVE tests on YOUR hardware: Microsoft Office
// (PWA pipeline), Logitech gear (native stack, detected in real time),
// Windows apps (Bottles), and game compatibility lookups.
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

    property bool officeReady: false
    property var logitechDevices: []
    property bool ratbagOk: false
    property bool solaarOk: false

    function refresh() { statusProc.running = true; ratbagProc.running = true }
    Component.onCompleted: refresh()

    Process {
        id: statusProc
        command: ["sh", "-c",
            "[ -f ~/.local/share/applications/hamadaos-word.desktop ] && echo office=yes || echo office=no; " +
            "command -v solaar >/dev/null && echo solaar=yes || echo solaar=no"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    if (line === "office=yes") root.officeReady = true
                    if (line === "office=no") root.officeReady = false
                    if (line === "solaar=yes") root.solaarOk = true
                }
            }
        }
    }

    // LIVE hardware test: what does libratbag actually see right now?
    Process {
        id: ratbagProc
        command: ["sh", "-c", "command -v ratbagctl >/dev/null && ratbagctl list 2>/dev/null || echo NORATBAG"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim()
                if (t === "NORATBAG" || t === "") {
                    root.ratbagOk = t !== "NORATBAG"
                    root.logitechDevices = []
                } else {
                    root.ratbagOk = true
                    // lines like: "singing-gundi: Logitech G502 HERO"
                    root.logitechDevices = t.split("\n")
                        .map(l => l.split(":").slice(1).join(":").trim())
                        .filter(l => l !== "")
                }
            }
        }
    }

    ColumnLayout {
        id: col
        width: root.width
        spacing: Theme.spaceLg

        // ═══ Microsoft Office ════════════════════════════════════════════════
        SectionTitle { text: "Microsoft Office" }

        Rectangle {
            Layout.fillWidth: true
            radius: Theme.radiusMd
            color: Theme.surface2
            implicitHeight: officeCol.implicitHeight + Theme.spaceMd * 2

            ColumnLayout {
                id: officeCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceMd }
                spacing: Theme.spaceSm

                RowLayout {
                    Text {
                        text: root.officeReady ? "󰄬" : "󰋗"
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.iconMd
                        color: root.officeReady ? Theme.colorSuccess : Theme.onSurfaceVar
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.officeReady
                            ? "Installed — Word, Excel, PowerPoint, Outlook & OneDrive are in your launcher"
                            : "Real Microsoft 365, each app in its own window (PWA via Edge)"
                        font.pixelSize: Theme.fontSizeSm
                        color: Theme.onSurface
                        wrapMode: Text.WordWrap
                    }
                }

                RowLayout {
                    spacing: Theme.spaceSm
                    Button {
                        text: root.officeReady ? "Reinstall" : "Set up Office"
                        onClicked: {
                            Quickshell.execDetached(["kitty", "--title", "Office Setup", "-e", "sh", "-c",
                                "~/.config/hypr/scripts/hamadaos-office-setup.sh setup; sleep 2"])
                            refreshTimer.restart()
                        }
                    }
                    Button { visible: root.officeReady; text: "Word"
                        onClicked: Quickshell.execDetached(["sh", "-c", "~/.config/hypr/scripts/hamadaos-office-setup.sh launch word"]) }
                    Button { visible: root.officeReady; text: "Excel"
                        onClicked: Quickshell.execDetached(["sh", "-c", "~/.config/hypr/scripts/hamadaos-office-setup.sh launch excel"]) }
                    Button { visible: root.officeReady; text: "PowerPoint"
                        onClicked: Quickshell.execDetached(["sh", "-c", "~/.config/hypr/scripts/hamadaos-office-setup.sh launch powerpoint"]) }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Straight truth: desktop Office binaries don't run under Wine (Click-to-Run blocks them — CrossOver included). " +
                          "These are Microsoft's own web apps: your account, OneDrive, co-editing, full fidelity for ~95% of work. " +
                          "Need VBA macros or COM add-ins? That requires WinApps (real binaries via a hidden VM) — search 'winapps github'. " +
                          "Local .docx files default to LibreOffice, which round-trips Office formats."
                    font.pixelSize: Theme.fontSizeXs
                    color: Theme.onSurfaceVar
                    wrapMode: Text.WordWrap
                }
            }
        }

        // ═══ Logitech ════════════════════════════════════════════════════════
        SectionTitle { text: "Logitech (G HUB replacement)" }

        Rectangle {
            Layout.fillWidth: true
            radius: Theme.radiusMd
            color: Theme.surface2
            implicitHeight: logiCol.implicitHeight + Theme.spaceMd * 2

            ColumnLayout {
                id: logiCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceMd }
                spacing: Theme.spaceSm

                // LIVE detection result
                RowLayout {
                    Text {
                        text: root.logitechDevices.length > 0 ? "󰄬" : "󰍽"
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.iconMd
                        color: root.logitechDevices.length > 0 ? Theme.colorSuccess : Theme.onSurfaceVar
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.logitechDevices.length > 0
                            ? "Detected now: " + root.logitechDevices.join(" · ")
                            : root.ratbagOk
                                ? "No configurable gaming mouse detected (plug it in and Refresh)"
                                : "Piper/libratbag not installed yet"
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: root.logitechDevices.length > 0 ? Font.Bold : Font.Normal
                        color: Theme.onSurface
                        wrapMode: Text.WordWrap
                    }
                    Button { text: "Refresh"; onClicked: root.refresh() }
                }

                RowLayout {
                    spacing: Theme.spaceSm
                    Button { text: "Mouse: DPI · buttons · RGB (Piper)"
                        onClicked: Quickshell.execDetached(["piper"]) }
                    Button { text: "Receivers & battery (Solaar)"
                        onClicked: Quickshell.execDetached(["solaar"]) }
                    Button { text: "Headset (sidetone/battery)"
                        onClicked: Quickshell.execDetached(["kitty", "--title", "HeadsetControl", "-e", "sh", "-c",
                            "headsetcontrol -b; headsetcontrol -?; exec bash"]) }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Straight truth: the G HUB app can't run — it installs Windows kernel drivers. But your hardware doesn't need it: " +
                          "Piper writes DPI stages, button remaps, and RGB to the mouse's ONBOARD memory — the same memory G HUB uses — " +
                          "so profiles persist with no daemon running, in games, even replugged into a Windows PC. " +
                          "Solaar covers Lightspeed/Unifying pairing and battery. Macros across apps: input-remapper."
                    font.pixelSize: Theme.fontSizeXs
                    color: Theme.onSurfaceVar
                    wrapMode: Text.WordWrap
                }
            }
        }

        // ═══ Windows apps & games ════════════════════════════════════════════
        SectionTitle { text: "Windows apps & games" }

        RowLayout {
            spacing: Theme.spaceSm
            Button { text: "Run a Windows .exe (Bottles)"
                onClicked: Quickshell.execDetached(["bottles"]) }
            Button { text: "Will my game run? (ProtonDB)"
                onClicked: Quickshell.execDetached(["xdg-open", "https://www.protondb.com"]) }
            Button { text: "Anticheat status (per game)"
                onClicked: Quickshell.execDetached(["xdg-open", "https://areweanticheatyet.com"]) }
        }
        Text {
            Layout.fillWidth: true
            text: "Steam games: just install — Proton-GE is set up. Multiplayer anticheat (EAC/BattlEye) works when the developer " +
                  "enables Linux support; check the per-game status before promising a friend. Non-Steam .exe apps go through Bottles."
            font.pixelSize: Theme.fontSizeXs
            color: Theme.onSurfaceVar
            wrapMode: Text.WordWrap
        }

        Timer { id: refreshTimer; interval: 4000; onTriggered: root.refresh() }
        Item { Layout.preferredHeight: Theme.spaceXl }
    }
}
