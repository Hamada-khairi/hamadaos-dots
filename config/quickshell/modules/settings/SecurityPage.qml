// HamadaOS Settings — Security (live fingerprint status)
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

    property string fprintStatus: "Checking…"
    property var enrolledFingers: []

    Component.onCompleted: fprintCheck.running = true

    function refreshFingerprints() { fprintCheck.running = true }

    Process {
        id: fprintCheck
        command: ["sh", "-c",
            "command -v fprintd-list >/dev/null || { echo none; exit 0; }; " +
            "fprintd-list \"$USER\" 2>/dev/null | grep -oE '[a-z]+-[a-z-]*finger' || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim()
                if (t === "none") {
                    root.fprintStatus = "fprintd not installed"
                    root.enrolledFingers = []
                } else if (t === "") {
                    root.fprintStatus = "No fingerprints enrolled"
                    root.enrolledFingers = []
                } else {
                    root.enrolledFingers = t.split("\n")
                    root.fprintStatus = root.enrolledFingers.length + " fingerprint(s) enrolled"
                }
            }
        }
    }

    // Friendly names, Windows-style ("Right index finger")
    function fingerLabel(id) {
        return id.replace(/-/g, " ").replace(/^./, c => c.toUpperCase())
    }

    // ── Security Center status (Windows Security equivalent) ────────────────
    property var sec: ({})

    function refreshStatus() { secProc.running = true }
    Component.onCompleted: refreshStatus()

    Process {
        id: secProc
        command: ["sh", "-c",
            "echo \"fw=$(systemctl is-active ufw 2>/dev/null)\"; " +
            "if [ -d /sys/firmware/efi ]; then " +
            "  sb=$(bootctl status 2>/dev/null | grep -i 'secure boot' | head -1 | grep -qi enabled && echo enabled || echo disabled); " +
            "  echo \"sb=$sb\"; else echo 'sb=bios'; fi; " +
            "lsblk -no TYPE 2>/dev/null | grep -q crypt && echo enc=yes || echo enc=no; " +
            "command -v fprintd-list >/dev/null && echo fp=yes || echo fp=no"]
        stdout: StdioCollector {
            onStreamFinished: {
                const result = {}
                for (const line of text.trim().split("\n")) {
                    const i = line.indexOf("=")
                    if (i > 0) result[line.slice(0, i)] = line.slice(i + 1)
                }
                root.sec = result
            }
        }
    }

    component StatusCard: Rectangle {
        property string icon: ""
        property string label: ""
        property string state: ""
        property bool good: false
        Layout.fillWidth: true
        implicitHeight: 64
        radius: Theme.radiusMd
        color: Theme.surface2
        border { width: 1; color: good ? Qt.rgba(Theme.colorSuccess.r, Theme.colorSuccess.g, Theme.colorSuccess.b, 0.5)
                                        : Qt.rgba(Theme.colorWarning.r, Theme.colorWarning.g, Theme.colorWarning.b, 0.5) }
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: parent.parent.icon + "  " + parent.parent.label
                font.pixelSize: Theme.fontSizeXs
                color: Theme.onSurfaceVar
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: parent.parent.state
                font.pixelSize: Theme.fontSizeSm
                font.weight: Font.Bold
                color: parent.parent.good ? Theme.colorSuccess : Theme.colorWarning
            }
        }
    }

    component ToolRow: Rectangle {
        property string icon: ""
        property string label: ""
        property string sub: ""
        property var command: []

        Layout.fillWidth: true
        implicitHeight: 56
        radius: Theme.radiusMd
        color: Theme.surface2

        RowLayout {
            anchors { fill: parent; leftMargin: Theme.spaceMd; rightMargin: Theme.spaceMd }
            spacing: Theme.spaceMd

            Text {
                text: parent.parent.icon
                font.family: Theme.fontMono
                font.pixelSize: Theme.iconMd
                color: Theme.primary
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    text: parent.parent.parent.label
                    font.pixelSize: Theme.fontSizeSm
                    font.weight: Font.Medium
                    color: Theme.onSurface
                }
                Text {
                    visible: text !== ""
                    text: parent.parent.parent.sub
                    font.pixelSize: Theme.fontSizeXs
                    color: Theme.onSurfaceVar
                }
            }
            Button {
                text: "Open"
                onClicked: Quickshell.execDetached(parent.parent.command)
            }
        }
    }

    ColumnLayout {
        id: col
        width: root.width
        spacing: Theme.spaceMd

        SectionTitle { text: "Security at a glance" }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceSm
            StatusCard {
                icon: "󰕥"; label: "Firewall"
                state: root.sec.fw === "active" ? "On" : "Off"
                good: root.sec.fw === "active"
            }
            StatusCard {
                icon: "󰒃"; label: "Secure Boot"
                state: root.sec.sb === "enabled" ? "On"
                     : root.sec.sb === "bios" ? "BIOS" : "Off"
                good: root.sec.sb === "enabled"
            }
            StatusCard {
                icon: "󰋊"; label: "Disk encryption"
                state: root.sec.enc === "yes" ? "LUKS" : "Off"
                good: root.sec.enc === "yes"
            }
        }

        RowLayout {
            spacing: Theme.spaceMd
            Button {
                text: root.sec.fw === "active" ? "Disable firewall" : "Enable firewall"
                onClicked: {
                    // pkexec → graphical password prompt, like Windows UAC
                    Quickshell.execDetached(["sh", "-c",
                        root.sec.fw === "active"
                            ? "pkexec sh -c 'ufw disable; systemctl disable --now ufw'"
                            : "pkexec sh -c 'systemctl enable --now ufw; ufw --force enable'"])
                    secRefresh.restart()
                }
            }
            Button { text: "Firewall rules…"; onClicked: Quickshell.execDetached(["gufw"]) }
        }
        Text {
            visible: root.sec.sb === "disabled"
            text: "Secure Boot is a BIOS setting — it can be read here but only changed in UEFI setup. Off is normal (and required) for some Linux setups."
            font.pixelSize: Theme.fontSizeXs
            color: Theme.onSurfaceVar
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        Timer { id: secRefresh; interval: 3000; onTriggered: root.refreshStatus() }

        SectionTitle { text: "Credentials" }

        ToolRow {
            icon: "󰌋"; label: "Passwords & keys"
            sub: "GNOME Keyring — SSH keys, app secrets, saved passwords"
            command: ["seahorse"]
        }

        SectionTitle { text: "Fingerprint (Windows Hello)" }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: fpCol.implicitHeight + Theme.spaceMd * 2
            radius: Theme.radiusMd
            color: Theme.surface2

            ColumnLayout {
                id: fpCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceMd }
                spacing: Theme.spaceSm

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spaceMd
                    Text {
                        text: "󰈷"
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.iconMd
                        color: Theme.primary
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            text: "Fingerprint sign-in"
                            font.pixelSize: Theme.fontSizeSm
                            font.weight: Font.Medium
                            color: Theme.onSurface
                        }
                        Text {
                            text: root.fprintStatus
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.onSurfaceVar
                        }
                    }
                    Button {
                        text: "Add fingerprint"
                        onClicked: {
                            Quickshell.execDetached(["kitty", "--title", "Enroll Fingerprint",
                                "-e", "sh", "-c", "fprintd-enroll; echo; echo Done — close this window."])
                            refreshTimer.restart()
                        }
                    }
                }

                // Enrolled fingers, Windows-style list
                Repeater {
                    model: root.enrolledFingers
                    RowLayout {
                        required property string modelData
                        Layout.fillWidth: true
                        Layout.leftMargin: Theme.spaceXl
                        Text {
                            text: "󰐾  " + root.fingerLabel(modelData)
                            font.pixelSize: Theme.fontSizeSm
                            color: Theme.onSurface
                            Layout.fillWidth: true
                        }
                    }
                }

                RowLayout {
                    visible: root.enrolledFingers.length > 0
                    Layout.leftMargin: Theme.spaceXl
                    Button {
                        text: "Remove all fingerprints"
                        onClicked: {
                            Quickshell.execDetached(["sh", "-c", "fprintd-delete \"$USER\""])
                            refreshTimer.restart()
                        }
                    }
                }
            }
        }
        Text {
            text: "Works for the lock screen and sudo (PAM). Re-open this page to refresh after enrolling."
            font.pixelSize: Theme.fontSizeXs
            color: Theme.onSurfaceVar
        }

        Timer {
            id: refreshTimer
            interval: 3000; repeat: false
            onTriggered: root.refreshFingerprints()
        }

        SectionTitle { text: "System" }

        ToolRow {
            icon: "󰋊"; label: "Disks & encryption (LUKS)"
            sub: "Partitioning, BitLocker-style encryption, S.M.A.R.T. health"
            command: ["gnome-disks"]
        }
        ToolRow {
            icon: "󰕥"; label: "Firewall"
            sub: "UFW rules with a GUI"
            command: ["gufw"]
        }
        ToolRow {
            icon: "󰁯"; label: "Snapshots (System Restore)"
            sub: "Btrfs snapshots — roll back any update"
            command: ["snapper-gui"]
        }

        Item { Layout.preferredHeight: Theme.spaceXl }
    }
}
