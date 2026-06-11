// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — App Launcher
// ═══════════════════════════════════════════════════════════════════════════════
// Built on Quickshell's DesktopEntries — real .desktop parsing, real icons,
// real launch (entry.execute() handles field codes, terminal apps, dbus
// activation). Full keyboard flow: type → arrows → Enter. Esc closes.
// ═══════════════════════════════════════════════════════════════════════════════

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import qs
import qs.modules.common

PanelWindow {
    id: launcher
    WlrLayershell.namespace: "quickshell:launcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusiveZone: 0
    color: Qt.rgba(0, 0, 0, 0.45)
    anchors { top: true; bottom: true; left: true; right: true }

    // ── Windows-name bridge ─────────────────────────────────────────────────
    // Search what you'd search on Windows; get the HamadaOS tool. This is the
    // muscle-memory layer: "device manager", "control panel", "task manager"
    // all resolve instantly — no need to learn Linux tool names.
    readonly property var windowsAliases: [
        { name: "Settings",            comment: "Control Panel · PC Settings",         icon: "preferences-system",
          keys: ["control panel", "settings", "pc settings"], action: "settings" },
        { name: "Task Manager",        comment: "Processes, performance, startup apps", icon: "utilities-system-monitor",
          keys: ["task manager", "taskmgr", "processes"], cmd: ["mission-center"] },
        { name: "Device Manager",      comment: "Hardware information & drivers",       icon: "computer",
          keys: ["device manager", "devmgmt", "hardware", "drivers"], cmd: ["hardinfo2"] },
        { name: "Disk Management",     comment: "Partitions, formatting, encryption",   icon: "drive-harddisk",
          keys: ["disk management", "diskmgmt", "partitions", "format drive"], cmd: ["gnome-disks"] },
        { name: "Add or Remove Programs", comment: "Install & uninstall software",      icon: "system-software-install",
          keys: ["add or remove", "programs and features", "appwiz", "store", "uninstall", "software"], cmd: ["pamac-manager"] },
        { name: "Snipping Tool",       comment: "Screenshot a region of the screen",    icon: "applets-screenshooter",
          keys: ["snipping tool", "snip", "screenshot"], cmd: ["sh", "-c", "hyde-shell screenshot sf"] },
        { name: "Network Connections", comment: "WiFi, Ethernet, VPN profiles",         icon: "network-wireless",
          keys: ["network connections", "ncpa", "vpn", "wifi settings"], cmd: ["nm-connection-editor"] },
        { name: "Windows Hello",       comment: "Fingerprint sign-in (Settings → Security)", icon: "fingerprint-gui",
          keys: ["windows hello", "fingerprint", "sign-in options"], action: "settings" },
        { name: "Display Settings",    comment: "Monitors, resolution, scale (Settings → Display)", icon: "preferences-desktop-display",
          keys: ["display settings", "screen resolution", "monitors", "projector"], action: "settings" },
        { name: "Default Apps",        comment: "Default browser, players, mail (Settings)", icon: "preferences-desktop-default-applications",
          keys: ["default apps", "default browser", "file associations"], action: "settings" },
        { name: "System Restore",      comment: "Btrfs snapshots — roll back updates",  icon: "document-revert",
          keys: ["system restore", "restore point", "snapshot", "rollback"], cmd: ["snapper-gui"] },
        { name: "Firewall",            comment: "Inbound/outbound rules (UFW)",         icon: "security-high",
          keys: ["firewall", "defender", "wf.msc"], cmd: ["gufw"] },
        { name: "Event Viewer",        comment: "System logs (journalctl)",             icon: "text-x-log",
          keys: ["event viewer", "eventvwr", "logs"], cmd: ["kitty", "--title", "System Logs", "-e", "journalctl", "-b", "-f"] },
        { name: "Phone Link",          comment: "Connect your Android/iPhone (KDE Connect)", icon: "phone",
          keys: ["phone link", "your phone", "kde connect"], cmd: ["kdeconnect-app"] },
        { name: "Magnifier",           comment: "Zoom the screen 2×",                   icon: "zoom-in",
          keys: ["magnifier", "magnify", "zoom"], cmd: ["hyprctl", "keyword", "cursor:zoom_factor", "2"] },
        { name: "On-Screen Color Picker", comment: "Pick a color from anywhere",        icon: "color-picker",
          keys: ["color picker", "powertoys color"], cmd: ["hyprpicker", "-a"] },
        { name: "MSI Afterburner",     comment: "GPU overclocking, fan curves, power limits (LACT)", icon: "video-display",
          keys: ["msi afterburner", "afterburner", "overclock", "gpu clock", "fan curve"], cmd: ["lact"] },
        { name: "GPU Control Panel",   comment: "Clocks, fans, profiles (CoreCtrl)",    icon: "video-display",
          keys: ["nvidia control panel", "gpu", "radeon settings"], cmd: ["corectrl"] },
        { name: "Mobile Hotspot",      comment: "Share this PC's internet over WiFi",   icon: "network-wireless-hotspot",
          keys: ["mobile hotspot", "hotspot", "tethering"], cmd: ["wihotspot"] },
        { name: "Printers & Scanners", comment: "Add and manage printers",              icon: "printer",
          keys: ["printers", "printers and scanners", "add printer"], cmd: ["system-config-printer"] },
        { name: "Keyboard Remapper",   comment: "Rebind keys & buttons (PowerToys Keyboard Manager)", icon: "input-keyboard",
          keys: ["keyboard manager", "remap keys", "rebind"], cmd: ["input-remapper-gtk"] },
        { name: "Run Windows Programs", comment: ".exe apps via Bottles (Wine)",        icon: "wine",
          keys: ["run exe", "wine", "windows programs", "bottles"], cmd: ["bottles"] },
        { name: "Discord (screenshare that works)", comment: "Vesktop — Wayland capture + audio sharing", icon: "discord",
          keys: ["discord", "screen share", "vesktop"], cmd: ["vesktop"] },
        { name: "Windows Update",      comment: "Check & install all updates (Settings → Health)", icon: "system-software-update",
          keys: ["windows update", "update", "check for updates"], action: "settings" },
        { name: "Troubleshoot",        comment: "One-click system check & fix (Settings → Health)", icon: "dialog-question",
          keys: ["troubleshoot", "fix", "doctor", "diagnose", "repair"], action: "settings" },
        { name: "ZoomIt",              comment: "Ctrl+Alt+1 zoom · Ctrl+Alt+2 draw on screen", icon: "zoom-in",
          keys: ["zoomit", "draw on screen", "annotate screen"], cmd: ["gromit-mpx", "--toggle"] },
        { name: "Recovery / Safe Mode", comment: "Rescue menu — fix, export logs, roll back", icon: "applications-system",
          keys: ["safe mode", "recovery", "rescue", "system restore point"],
          cmd: ["kitty", "--title", "HamadaOS Rescue", "-e", "sh", "-c", "~/.config/hypr/scripts/hamadaos-rescue.sh"] },
        { name: "Backup my settings",  comment: "Export shell + display + game configs", icon: "document-save",
          keys: ["backup", "export settings", "file history"],
          cmd: ["sh", "-c", "~/.config/hypr/scripts/hamadaos-backup.sh export"] },
        { name: "Controllers",         comment: "Gamepad battery & remapping (Settings → Tools)", icon: "input-gaming",
          keys: ["controller", "gamepad", "xbox", "dualsense", "joystick"], action: "settings" },
        { name: "Word",                comment: "Microsoft Word (own window, your account)", icon: "ms-word",
          keys: ["word", "microsoft word", "winword"],
          cmd: ["sh", "-c", "~/.config/hypr/scripts/hamadaos-office-setup.sh launch word"] },
        { name: "Excel",               comment: "Microsoft Excel", icon: "ms-excel",
          keys: ["excel", "spreadsheet", "microsoft excel"],
          cmd: ["sh", "-c", "~/.config/hypr/scripts/hamadaos-office-setup.sh launch excel"] },
        { name: "PowerPoint",          comment: "Microsoft PowerPoint", icon: "ms-powerpoint",
          keys: ["powerpoint", "presentation", "ppt"],
          cmd: ["sh", "-c", "~/.config/hypr/scripts/hamadaos-office-setup.sh launch powerpoint"] },
        { name: "Microsoft 365",       comment: "Office home · Outlook · OneDrive", icon: "ms-office",
          keys: ["office", "microsoft 365", "outlook", "onedrive"],
          cmd: ["sh", "-c", "~/.config/hypr/scripts/hamadaos-office-setup.sh launch office"] },
        { name: "G HUB (Piper)",       comment: "Logitech mouse: DPI, buttons, RGB — onboard profiles", icon: "input-mouse",
          keys: ["g hub", "ghub", "logitech", "dpi", "mouse settings"], cmd: ["piper"] }
    ]

    readonly property list<var> apps: {
        const q = searchInput.text.toLowerCase().trim()
        const all = [...DesktopEntries.applications.values]
            .filter(e => !e.noDisplay)
            .sort((a, b) => a.name.localeCompare(b.name))
        if (q === "") return all

        // Windows-name aliases first when they match.
        const aliasHits = windowsAliases.filter(a =>
            a.keys.some(k => k.includes(q) || q.includes(k))
            || a.name.toLowerCase().includes(q))

        // Then name-prefix matches, name-contains, keyword/comment.
        const starts = [], contains = [], meta = []
        for (const e of all) {
            const name = e.name.toLowerCase()
            if (name.startsWith(q)) starts.push(e)
            else if (name.includes(q)) contains.push(e)
            else if ((e.comment ?? "").toLowerCase().includes(q)
                  || (e.genericName ?? "").toLowerCase().includes(q)) meta.push(e)
        }
        return [...aliasHits, ...starts, ...contains, ...meta]
    }

    property int selectedIndex: 0

    function launchSelected() {
        const entry = apps[selectedIndex]
        if (!entry) return
        if (entry.action === "settings") {
            GlobalStates.settingsOpen = true
        } else if (entry.cmd) {
            Quickshell.execDetached(entry.cmd)
        } else {
            entry.execute()
        }
        GlobalStates.launcherOpen = false
    }

    // Click outside closes.
    MouseArea {
        anchors.fill: parent
        onClicked: GlobalStates.launcherOpen = false
    }

    Rectangle {
        id: panel
        width: 600
        height: 480
        radius: Theme.radiusXl
        anchors.centerIn: parent
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, Theme.opacityPopup)
        border { width: 1; color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.35) }

        scale: 1.0
        Component.onCompleted: { scale = 0.92; scale = 1.0 }
        Behavior on scale { SpringAnimation { spring: 4.0; damping: 0.8; epsilon: 0.01 } }

        MouseArea { anchors.fill: parent }   // swallow clicks inside the panel

        ColumnLayout {
            anchors { fill: parent; margins: Theme.spaceXl }
            spacing: Theme.spaceMd

            // ── Search ───────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 46
                radius: Theme.radiusMd
                color: Theme.surface2
                border { width: 1; color: searchInput.activeFocus ? Theme.primary : "transparent" }

                RowLayout {
                    anchors { fill: parent; leftMargin: Theme.spaceMd; rightMargin: Theme.spaceMd }
                    spacing: Theme.spaceSm

                    Text {
                        text: "󰍉"
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.iconMd
                        color: Theme.onSurfaceVar
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fontSizeLg
                        color: Theme.onSurface
                        clip: true
                        focus: true

                        onTextChanged: launcher.selectedIndex = 0
                        Keys.onReturnPressed: launcher.launchSelected()
                        Keys.onEscapePressed: GlobalStates.launcherOpen = false
                        Keys.onDownPressed: launcher.selectedIndex =
                            Math.min(launcher.selectedIndex + 1, launcher.apps.length - 1)
                        Keys.onUpPressed: launcher.selectedIndex =
                            Math.max(launcher.selectedIndex - 1, 0)

                        Text {
                            anchors.fill: parent
                            visible: searchInput.text === ""
                            text: "Search apps…"
                            font: searchInput.font
                            color: Theme.onSurfaceVar
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            // ── Results ──────────────────────────────────────────────────────
            ListView {
                id: resultList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: launcher.apps
                currentIndex: launcher.selectedIndex
                highlightMoveDuration: Theme.durationFast
                spacing: 2

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width: resultList.width
                    height: 52
                    radius: Theme.radiusMd
                    color: index === launcher.selectedIndex ? Theme.primaryGlow
                         : rowMa.containsMouse ? Theme.hoverOverlay : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                    RowLayout {
                        anchors { fill: parent; leftMargin: Theme.spaceMd; rightMargin: Theme.spaceMd }
                        spacing: Theme.spaceMd

                        IconImage {
                            implicitSize: 32
                            source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                font.family: Theme.fontSans
                                font.pixelSize: Theme.fontSizeMd
                                color: Theme.onSurface
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: modelData.comment ?? ""
                                font.pixelSize: Theme.fontSizeXs
                                color: Theme.onSurfaceVar
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        id: rowMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: launcher.selectedIndex = index
                        onClicked: launcher.launchSelected()
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: launcher.apps.length + " apps   ·   ↑↓ navigate   ·   ↵ launch   ·   Esc close"
                font.pixelSize: Theme.fontSizeXs
                color: Theme.onSurfaceVar
            }
        }
    }
}
