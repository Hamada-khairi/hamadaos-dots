// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Network Service (event-driven nmcli)
// ═══════════════════════════════════════════════════════════════════════════════
// `nmcli monitor` streams NetworkManager events — we refresh state only when
// something actually changes, instead of polling. WiFi scanning is on-demand.
// ═══════════════════════════════════════════════════════════════════════════════

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool wifiEnabled: true
    property bool connected: false
    property string connectionType: ""    // "wifi" | "ethernet" | ""
    property string activeSsid: ""
    property int signalStrength: 0        // 0–100 for the active wifi connection
    property var networks: []             // [{ ssid, signal, secure, inUse }]
    property bool scanning: false

    property string materialIcon: {
        if (!connected) return "󰤮"
        if (connectionType === "ethernet") return "󰈀"
        if (signalStrength >= 80) return "󰤨"
        if (signalStrength >= 55) return "󰤥"
        if (signalStrength >= 30) return "󰤢"
        return "󰤟"
    }

    function toggleWifi() {
        Quickshell.execDetached(["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"])
        wifiEnabled = !wifiEnabled
    }

    function connect(ssid, password) {
        if (password && password.length > 0)
            Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", ssid, "password", password])
        else
            Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", ssid])
    }

    function disconnect(ssid) {
        Quickshell.execDetached(["nmcli", "connection", "down", "id", ssid])
    }

    function rescan() {
        scanning = true
        scanProc.running = true
    }

    function refreshState() { stateProc.running = true }

    // ── Live event stream — refresh on any NetworkManager change ────────────
    Process {
        id: monitorProc
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: refreshDebounce.restart()
        }
    }
    Timer {
        id: refreshDebounce
        interval: 500; repeat: false
        onTriggered: root.refreshState()
    }

    // ── Connection state ─────────────────────────────────────────────────────
    Process {
        id: stateProc
        command: ["sh", "-c",
            "nmcli radio wifi; nmcli -t -f TYPE,STATE,CONNECTION device status | grep -E '^(wifi|ethernet)' | head -2; " +
            "nmcli -t -f IN-USE,SIGNAL,SSID dev wifi list 2>/dev/null | grep '^\\*' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                root.wifiEnabled = lines[0]?.trim() === "enabled"
                root.connected = false
                root.connectionType = ""
                root.activeSsid = ""
                for (let i = 1; i < lines.length; i++) {
                    const parts = lines[i].split(":")
                    if (parts[0] === "ethernet" && parts[1] === "connected") {
                        root.connected = true; root.connectionType = "ethernet"
                    } else if (parts[0] === "wifi" && parts[1] === "connected") {
                        root.connected = true
                        if (root.connectionType === "") root.connectionType = "wifi"
                        root.activeSsid = parts[2] ?? ""
                    } else if (parts[0] === "*") {
                        root.signalStrength = parseInt(parts[1]) || 0
                        if (!root.activeSsid) root.activeSsid = parts.slice(2).join(":")
                    }
                }
            }
        }
    }

    // ── WiFi scan (on-demand, used by the Network settings page) ────────────
    Process {
        id: scanProc
        command: ["sh", "-c", "nmcli dev wifi rescan 2>/dev/null; sleep 2; nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID dev wifi list 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const result = []
                const seen = {}
                for (const line of text.trim().split("\n")) {
                    // IN-USE:SIGNAL:SECURITY:SSID — SSID may itself contain ':'
                    const parts = line.split(":")
                    if (parts.length < 4) continue
                    const ssid = parts.slice(3).join(":").trim()
                    if (!ssid || seen[ssid]) continue
                    seen[ssid] = true
                    result.push({
                        ssid: ssid,
                        signal: parseInt(parts[1]) || 0,
                        secure: parts[2].trim() !== "" && parts[2].trim() !== "--",
                        inUse: parts[0].trim() === "*"
                    })
                }
                result.sort((a, b) => (b.inUse - a.inUse) || (b.signal - a.signal))
                root.networks = result
                root.scanning = false
            }
        }
    }

    Component.onCompleted: refreshState()
}
