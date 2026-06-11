// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Default Apps Service (Windows "Default apps" equivalent)
// ═══════════════════════════════════════════════════════════════════════════════
// Reads and writes XDG defaults through the standard tools (xdg-settings for
// the browser, xdg-mime for everything else) so the choices apply to ALL
// apps — Dolphin, browsers, file pickers, "open with" menus, everything.
//
// roles: browser · fileManager · mail · pdf · images · video · music · editor
// ═══════════════════════════════════════════════════════════════════════════════

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // role → primary mime (queried) and extra mimes (set together)
    readonly property var roles: ({
        browser:     { label: "Web browser",  icon: "󰖟", category: "WebBrowser",
                       mime: "x-scheme-handler/http",
                       extra: ["x-scheme-handler/https", "text/html"] },
        fileManager: { label: "File manager", icon: "󰉋", category: "FileManager",
                       mime: "inode/directory", extra: [] },
        mail:        { label: "Email",        icon: "󰇮", category: "Email",
                       mime: "x-scheme-handler/mailto", extra: [] },
        pdf:         { label: "PDF viewer",   icon: "󰈦", category: "Viewer",
                       mime: "application/pdf", extra: [] },
        images:      { label: "Photos",       icon: "󰋩", category: "Graphics",
                       mime: "image/png",
                       extra: ["image/jpeg", "image/webp", "image/gif", "image/bmp"] },
        video:       { label: "Video player", icon: "󰕧", category: "Video",
                       mime: "video/mp4",
                       extra: ["video/x-matroska", "video/webm", "video/x-msvideo"] },
        music:       { label: "Music player", icon: "󰝚", category: "Audio",
                       mime: "audio/mpeg",
                       extra: ["audio/flac", "audio/ogg", "audio/x-wav"] },
        editor:      { label: "Text editor",  icon: "󰷈", category: "TextEditor",
                       mime: "text/plain", extra: [] }
    })

    // role → current default desktop-file id (e.g. "firefox.desktop")
    property var current: ({})

    function refresh() { queryProc.running = true }

    Process {
        id: queryProc
        command: ["sh", "-c",
            "echo browser=$(xdg-settings get default-web-browser 2>/dev/null); " +
            "echo fileManager=$(xdg-mime query default inode/directory 2>/dev/null); " +
            "echo mail=$(xdg-mime query default x-scheme-handler/mailto 2>/dev/null); " +
            "echo pdf=$(xdg-mime query default application/pdf 2>/dev/null); " +
            "echo images=$(xdg-mime query default image/png 2>/dev/null); " +
            "echo video=$(xdg-mime query default video/mp4 2>/dev/null); " +
            "echo music=$(xdg-mime query default audio/mpeg 2>/dev/null); " +
            "echo editor=$(xdg-mime query default text/plain 2>/dev/null)"]
        stdout: StdioCollector {
            onStreamFinished: {
                const result = {}
                for (const line of text.trim().split("\n")) {
                    const idx = line.indexOf("=")
                    if (idx > 0) result[line.slice(0, idx)] = line.slice(idx + 1).trim()
                }
                root.current = result
            }
        }
    }

    // Apps that can plausibly fill a role (by .desktop Categories).
    function candidatesFor(roleKey) {
        const cat = roles[roleKey].category
        let list = [...DesktopEntries.applications.values]
            .filter(e => !e.noDisplay && e.categories.includes(cat))
        // Viewer/TextEditor categories are sparse — widen sensibly.
        if (list.length === 0 && roleKey === "pdf")
            list = [...DesktopEntries.applications.values].filter(e =>
                !e.noDisplay && (e.categories.includes("Office") || e.categories.includes("Graphics")))
        if (list.length === 0 && roleKey === "editor")
            list = [...DesktopEntries.applications.values].filter(e =>
                !e.noDisplay && e.categories.includes("Utility"))
        return list.sort((a, b) => a.name.localeCompare(b.name))
    }

    function setDefault(roleKey, desktopId) {
        const id = desktopId.endsWith(".desktop") ? desktopId : desktopId + ".desktop"
        if (roleKey === "browser") {
            Quickshell.execDetached(["xdg-settings", "set", "default-web-browser", id])
        } else {
            const role = roles[roleKey]
            Quickshell.execDetached(["xdg-mime", "default", id, role.mime, ...role.extra])
        }
        // Optimistic update; re-query to confirm.
        const next = Object.assign({}, current)
        next[roleKey] = id
        current = next
        confirmTimer.restart()
    }

    Timer {
        id: confirmTimer
        interval: 800; repeat: false
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
