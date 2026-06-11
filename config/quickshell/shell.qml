//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Quickshell Entry Point
// ═══════════════════════════════════════════════════════════════════════════════
// Launched by HyDE via ~/.config/hyde/config.toml:
//   [hyprland-start]
//   bar = "hyde-shell app -u hyde-$XDG_SESSION_DESKTOP-bar.scope -t scope -- quickshell"
//
// Panels are toggled two ways, both real Quickshell APIs:
//   1. GlobalShortcut — Hyprland binds `global, quickshell:<name>` (zero-latency)
//   2. IpcHandler     — `qs ipc call hamadaos <fn>` from scripts/terminal
//
// Reference: end-4/dots-hyprland shell.qml (ShellRoot + GlobalShortcut + IpcHandler)
// ═══════════════════════════════════════════════════════════════════════════════

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.services
import qs.modules.bar
import qs.modules.controlCenter
import qs.modules.notifications
import qs.modules.launcher
import qs.modules.overview
import qs.modules.dock
import qs.modules.osd
import qs.modules.session
import qs.modules.settings
import qs.modules.desktop
import qs.modules.onboarding

ShellRoot {
    id: root

    // ── Always-on surfaces ─────────────────────────────────────────────────
    Bar { }
    Notifications { }
    Osd { }
    ControlCenter { }

    // ── On-demand surfaces (lazy: zero cost until first opened) ────────────
    LazyLoader { active: GlobalStates.launcherOpen;   component: Launcher { } }
    LazyLoader { active: GlobalStates.overviewOpen;   component: Overview { } }
    LazyLoader { active: GlobalStates.powerMenuOpen;  component: PowerMenu { } }
    LazyLoader { active: GlobalStates.settingsOpen;   component: SettingsWindow { } }
    LazyLoader { active: Config.options.dockEnabled;  component: Dock { } }
    LazyLoader { active: Config.options.desktopIconsEnabled; component: DesktopIcons { } }
    LazyLoader { active: Config.ready && !Config.options.firstRunDone; component: WelcomeWindow { } }

    // ── Boot services that need a kick (singletons are lazy by default) ────
    Component.onCompleted: {
        NightLightService.restore()
        GamingService.restore()
        ScreenshareService.init()
    }

    // ═══════════════════════════════════════════════════════════════════════
    // GLOBAL SHORTCUTS — bind in Hyprland with:  bind = SUPER, C, global, quickshell:<name>
    // ═══════════════════════════════════════════════════════════════════════

    GlobalShortcut {
        name: "controlCenterToggle"
        description: "Toggle the HamadaOS control center"
        onPressed: GlobalStates.controlCenterOpen = !GlobalStates.controlCenterOpen
    }
    GlobalShortcut {
        name: "launcherToggle"
        description: "Toggle the HamadaOS app launcher"
        onPressed: GlobalStates.launcherOpen = !GlobalStates.launcherOpen
    }
    GlobalShortcut {
        name: "overviewToggle"
        description: "Toggle the HamadaOS task overview"
        onPressed: GlobalStates.overviewOpen = !GlobalStates.overviewOpen
    }
    GlobalShortcut {
        name: "settingsToggle"
        description: "Open the HamadaOS settings app"
        onPressed: GlobalStates.settingsOpen = !GlobalStates.settingsOpen
    }
    GlobalShortcut {
        name: "powerMenuToggle"
        description: "Open the HamadaOS power menu"
        onPressed: GlobalStates.powerMenuOpen = !GlobalStates.powerMenuOpen
    }

    // ═══════════════════════════════════════════════════════════════════════
    // IPC — `qs ipc call hamadaos <function>` (scripts, terminal, hooks)
    // ═══════════════════════════════════════════════════════════════════════

    IpcHandler {
        target: "hamadaos"

        function toggleControlCenter(): void { GlobalStates.controlCenterOpen = !GlobalStates.controlCenterOpen }
        function toggleLauncher(): void      { GlobalStates.launcherOpen = !GlobalStates.launcherOpen }
        function toggleOverview(): void      { GlobalStates.overviewOpen = !GlobalStates.overviewOpen }
        function openSettings(): void        { GlobalStates.settingsOpen = true }
        function togglePowerMenu(): void     { GlobalStates.powerMenuOpen = !GlobalStates.powerMenuOpen }
        function toggleNightLight(): void    { NightLightService.toggle() }
        function closeAll(): void            { GlobalStates.closeAll() }

        // Called by wallpaper-hook.sh after matugen regenerates colors.
        // GeneratedColors.qml hot-reloads on its own; this is for confirmation.
        function themeReloaded(): string {
            console.log("[HamadaOS] Theme reload signal received.")
            return "ok"
        }
    }
}
