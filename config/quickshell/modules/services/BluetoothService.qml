// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Bluetooth Service (native Quickshell.Bluetooth)
// ═══════════════════════════════════════════════════════════════════════════════
// Live BlueZ bindings — adapter power, discovery, device list, connect and
// pair are all event-driven object properties. No bluetoothctl parsing.
// ═══════════════════════════════════════════════════════════════════════════════

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    property var adapter: Bluetooth.defaultAdapter
    property bool available: adapter !== null
    property bool enabled: adapter?.enabled ?? false
    property bool discovering: adapter?.discovering ?? false

    readonly property list<var> devices: adapter
        ? [...adapter.devices.values].sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired))
        : []
    readonly property list<var> connectedDevices: devices.filter(d => d.connected)

    function togglePower() {
        if (adapter) adapter.enabled = !adapter.enabled
    }

    function toggleDiscovery() {
        if (adapter) adapter.discovering = !adapter.discovering
    }

    function connectDevice(device) {
        if (!device.paired) device.pair()
        device.connect()
    }

    function disconnectDevice(device) {
        device.disconnect()
    }

    function deviceIcon(device) {
        if (device.connected) return "󰂱"
        if (device.paired) return "󰂯"
        return "󰂲"
    }
}
