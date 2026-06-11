// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Settings Persistence Singleton
// ═══════════════════════════════════════════════════════════════════════════════
// Every user-facing setting lives here, persisted automatically to
// ~/.config/hamadaos/config.json (outside the dotfiles repo, so the repo
// stays clean and chezmoi diffs stay readable).
//
// Pattern (proven by end-4/dots-hyprland): FileView + JsonAdapter.
//   - Write a setting:  Config.options.darkMode = false   → auto-saved (debounced)
//   - Read a setting:   Config.options.darkMode           → reactive binding
//   - External edits (chezmoi apply, manual) hot-reload via watchChanges.
// ═══════════════════════════════════════════════════════════════════════════════

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string filePath: Quickshell.env("HOME") + "/.config/hamadaos/config.json"
    property alias options: adapter
    property bool ready: false

    // Debounce so slider drags don't hammer the disk.
    Timer {
        id: writeTimer
        interval: 250
        repeat: false
        onTriggered: configFile.writeAdapter()
    }

    Timer {
        id: reloadTimer
        interval: 100
        repeat: false
        onTriggered: configFile.reload()
    }

    FileView {
        id: configFile
        path: root.filePath
        watchChanges: true
        onFileChanged: reloadTimer.restart()
        onAdapterUpdated: writeTimer.restart()
        onLoaded: root.ready = true
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                // First run — write defaults.
                writeAdapter()
                root.ready = true
            }
        }

        JsonAdapter {
            id: adapter

            // ── First run ─────────────────────────────────────────────────
            property bool firstRunDone: false

            // ── Appearance ────────────────────────────────────────────────
            property bool darkMode: true
            property bool blur: true
            property real blurStrength: 0.85

            // ── Animations ────────────────────────────────────────────────
            property bool animations: true
            property real animationSpeed: 1.0
            property string animationPreset: "iOS Spring"

            // ── Bar ───────────────────────────────────────────────────────
            property string barPosition: "top"   // "top" | "bottom"

            // ── Desktop ───────────────────────────────────────────────────
            property bool desktopIconsEnabled: true

            // ── Dock ──────────────────────────────────────────────────────
            property bool dockEnabled: true
            property bool dockAutoHide: false
            property list<string> dockPinnedApps: [
                "firefox", "org.kde.dolphin", "code", "kitty",
                "steam", "io.missioncenter.MissionCenter"
            ]

            // ── Wallpaper & theming ───────────────────────────────────────
            property bool matugenEnabled: true
            property string wallpaperPath: ""

            // ── System ────────────────────────────────────────────────────
            property string temperatureUnit: "C"
            property string timeFormat: "24h"    // "12h" | "24h"

            // ── Gaming ────────────────────────────────────────────────────
            property bool gamingMode: false
            property bool mangoHudEnabled: false
            // TDP-shared thin laptops: cap CPU boost so the GPU gets the watts
            property bool gpuPriority: false
            // gamescope FSR upscaling (read by hamadaos-game-run via jq)
            property bool gamescopeEnabled: false
            property int gamescopeOutW: 1920
            property int gamescopeOutH: 1080
            property int gamescopeScale: 75      // render % of output res
            property int gamescopeFpsCap: 0      // 0 = uncapped

            // ── Notifications ─────────────────────────────────────────────
            property bool doNotDisturb: false
            property int notificationTimeout: 6000

            // ── Accessibility ─────────────────────────────────────────────
            property real textScale: 1.0

            // ── Night light ───────────────────────────────────────────────
            property bool nightLight: false
            property real nightLightTemp: 3500
        }
    }
}
