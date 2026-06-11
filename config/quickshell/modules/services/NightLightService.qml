// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Night Light Service (hyprsunset)
// ═══════════════════════════════════════════════════════════════════════════════
// HyDE already runs hyprsunset as its blue-light-filter daemon, and Hyprland
// exposes it over IPC — so toggling is a single hyprctl call with no extra
// process to manage:
//
//   hyprctl hyprsunset temperature 3500   → warm
//   hyprctl hyprsunset identity           → off (native colors)
// ═══════════════════════════════════════════════════════════════════════════════

pragma Singleton
import QtQuick
import Quickshell
import qs.modules.common

Singleton {
    id: root

    property bool enabled: Config.options.nightLight
    property real temperature: Config.options.nightLightTemp

    function toggle() {
        enabled ? disable() : enable()
    }

    function enable() {
        Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature",
                                 String(Math.round(temperature))])
        Config.options.nightLight = true
    }

    function disable() {
        Quickshell.execDetached(["hyprctl", "hyprsunset", "identity"])
        Config.options.nightLight = false
    }

    function setTemperature(temp) {
        temperature = temp
        Config.options.nightLightTemp = temp
        if (enabled)
            Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature",
                                     String(Math.round(temp))])
    }

    // Re-apply persisted state after login / shell restart.
    function restore() {
        if (Config.options.nightLight) enable()
    }
}
