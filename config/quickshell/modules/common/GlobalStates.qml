// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Global UI States
// ═══════════════════════════════════════════════════════════════════════════════
// Single source of truth for which panels are open. Anything — a bar button,
// a GlobalShortcut, an IpcHandler — flips these booleans, and the panels
// react via bindings. No process spawning, no round-trips.
// ═══════════════════════════════════════════════════════════════════════════════

pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property bool launcherOpen: false
    property bool controlCenterOpen: false
    property bool overviewOpen: false
    property bool settingsOpen: false
    property bool powerMenuOpen: false

    // Close every overlay (bound to Esc and to click-outside areas).
    function closeAll() {
        launcherOpen = false
        controlCenterOpen = false
        overviewOpen = false
        powerMenuOpen = false
    }
}
