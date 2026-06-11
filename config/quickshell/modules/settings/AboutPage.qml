// HamadaOS Settings — About (all values live, nothing hardcoded)
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common

Flickable {
    id: root
    contentHeight: col.implicitHeight
    clip: true

    property var info: ({})

    Component.onCompleted: infoProc.running = true

    Process {
        id: infoProc
        command: ["sh", "-c",
            "echo \"kernel=$(uname -r)\"; " +
            "echo \"hyprland=$(hyprctl version -j 2>/dev/null | head -c 400 | grep -o '\"tag\": *\"[^\"]*\"' | cut -d'\"' -f4)\"; " +
            "echo \"uptime=$(uptime -p | sed 's/^up //')\"; " +
            "echo \"cpu=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)\"; " +
            "echo \"gpu=$(lspci | grep -iE 'vga|3d' | head -1 | cut -d: -f3 | xargs)\"; " +
            "echo \"ram=$(free -h --si | awk '/^Mem:/{print $2}')\"; " +
            "echo \"disk=$(df -h / | awk 'NR==2{print $4\" free of \"$2}')\"; " +
            // ── Drivers (the Windows "Device Manager" answer) ──
            "for c in /sys/class/drm/card?; do " +
            "  d=$(basename $(readlink -f $c/device/driver 2>/dev/null) 2>/dev/null); " +
            "  [ -n \"$d\" ] && drv=\"$drv$d \"; done; " +
            "echo \"gpudrivers=${drv:-unknown}\"; " +
            "if command -v nvidia-smi >/dev/null 2>&1; then " +
            "  echo \"nvidia=proprietary $(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1)\"; " +
            "elif lsmod | grep -q nouveau; then echo 'nvidia=nouveau (open source — install nvidia-dkms for gaming)'; " +
            "else echo 'nvidia=none'; fi; " +
            "echo \"mesa=$(pacman -Q mesa 2>/dev/null | awk '{print $2}')\"; " +
            "echo \"wifi=$(lspci -k 2>/dev/null | grep -A2 -i 'network controller' | grep 'in use' | cut -d: -f2 | xargs)\"; " +
            "echo \"audio=$(pactl info 2>/dev/null | grep 'Server Name' | cut -d: -f2 | xargs)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const result = {}
                for (const line of text.trim().split("\n")) {
                    const idx = line.indexOf("=")
                    if (idx > 0) result[line.slice(0, idx)] = line.slice(idx + 1)
                }
                root.info = result
            }
        }
    }

    ColumnLayout {
        id: col
        width: root.width
        spacing: Theme.spaceLg

        ColumnLayout {
            spacing: Theme.spaceXs
            Text {
                text: "HamadaOS"
                font.family: Theme.fontDisplay
                font.pixelSize: Theme.fontSize2xl
                font.weight: Font.Bold
                color: Theme.primary
            }
            Text {
                text: "Version 3 — \"The Gaming Desktop\""
                font.pixelSize: Theme.fontSizeMd
                color: Theme.onSurfaceVar
            }
            Text {
                text: "CachyOS · HyDE · Hyprland · Quickshell"
                font.pixelSize: Theme.fontSizeXs
                color: Theme.onSurfaceVar
            }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.outline; opacity: 0.3 }

        GridLayout {
            columns: 2
            columnSpacing: Theme.spaceXl
            rowSpacing: Theme.spaceSm

            component K: Text { font.pixelSize: Theme.fontSizeSm; color: Theme.onSurfaceVar }
            component V: Text { font.pixelSize: Theme.fontSizeSm; font.family: Theme.fontMono; color: Theme.onSurface }

            K { text: "Kernel" }    V { text: root.info.kernel ?? "…" }
            K { text: "Hyprland" }  V { text: root.info.hyprland ?? "…" }
            K { text: "CPU" }       V { text: root.info.cpu ?? "…" }
            K { text: "GPU" }       V { text: root.info.gpu ?? "…" }
            K { text: "RAM" }       V { text: root.info.ram ?? "…" }
            K { text: "Storage" }   V { text: root.info.disk ?? "…" }
            K { text: "Uptime" }    V { text: root.info.uptime ?? "…" }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.outline; opacity: 0.3 }

        SectionTitle { text: "Drivers" }

        GridLayout {
            columns: 2
            columnSpacing: Theme.spaceXl
            rowSpacing: Theme.spaceSm

            component DK: Text { font.pixelSize: Theme.fontSizeSm; color: Theme.onSurfaceVar }
            component DV: Text { font.pixelSize: Theme.fontSizeSm; font.family: Theme.fontMono; color: Theme.onSurface }

            DK { text: "GPU kernel drivers" }  DV { text: root.info.gpudrivers ?? "…" }
            DK { text: "NVIDIA" }              DV {
                text: root.info.nvidia ?? "…"
                color: (root.info.nvidia ?? "").includes("nouveau") ? Theme.colorWarning : Theme.onSurface
            }
            DK { text: "Mesa (AMD/Intel)" }    DV { text: root.info.mesa ?? "…" }
            DK { text: "WiFi driver" }         DV { text: root.info.wifi ?? "…" }
            DK { text: "Audio server" }        DV { text: root.info.audio ?? "…" }
        }

        Button {
            text: "Full hardware report (Device Manager)…"
            onClicked: Quickshell.execDetached(["hardinfo2"])
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.outline; opacity: 0.3 }

        SectionTitle { text: "Credits" }
        Text {
            Layout.fillWidth: true
            text: "Hyprland · Quickshell · HyDE · matugen · Catppuccin\nend-4/dots-hyprland · ilyamiro/imperative-dots · samyns/Unit-3\nCachyOS team · Arch Linux · every package maintainer"
            font.pixelSize: Theme.fontSizeSm
            color: Theme.onSurfaceVar
            lineHeight: 1.4
        }

        Item { Layout.preferredHeight: Theme.spaceXl }
    }
}
