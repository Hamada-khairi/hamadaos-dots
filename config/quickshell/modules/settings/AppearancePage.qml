// HamadaOS Settings — Appearance
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common

Flickable {
    id: root
    contentHeight: col.implicitHeight
    clip: true

    ColumnLayout {
        id: col
        width: root.width
        spacing: Theme.spaceLg

        SectionTitle { text: "Wallpaper & Colors" }

        Text {
            Layout.fillWidth: true
            text: "The wallpaper drives every color on the desktop — shell, terminal, GTK, Qt, even VS Code — through the matugen pipeline."
            font.pixelSize: Theme.fontSizeSm
            color: Theme.onSurfaceVar
            wrapMode: Text.WordWrap
        }

        RowLayout {
            spacing: Theme.spaceMd
            Button {
                text: "Choose wallpaper…"
                onClicked: Quickshell.execDetached(["sh", "-c",
                    "f=$(zenity --file-selection --title='Choose Wallpaper' --file-filter='Images | *.jpg *.jpeg *.png *.webp' 2>/dev/null); " +
                    "[ -n \"$f\" ] && ~/.config/hypr/scripts/wallpaper.sh \"$f\""])
            }
            Button {
                text: "HyDE wallpaper gallery"
                onClicked: Quickshell.execDetached(["hyde-shell", "wallpaper", "--select"])
            }
        }

        RowLayout {
            spacing: Theme.spaceMd
            Rectangle { width: 36; height: 36; radius: Theme.radiusFull; color: Theme.primary }
            Rectangle { width: 36; height: 36; radius: Theme.radiusFull; color: Theme.secondary }
            Rectangle { width: 36; height: 36; radius: Theme.radiusFull; color: Theme.tertiary }
            Rectangle { width: 36; height: 36; radius: Theme.radiusFull; color: Theme.surfaceVariant }
            Text {
                text: "Current palette (from wallpaper)"
                font.pixelSize: Theme.fontSizeSm
                color: Theme.onSurfaceVar
                Layout.leftMargin: Theme.spaceSm
            }
        }

        SectionTitle { text: "Shell" }

        ToggleRow {
            label: "Blur effects"
            description: "Frosted glass on panels. Off = solid panels, slightly more FPS."
            checked: Config.options.blur
            onToggled: newState => Config.options.blur = newState
        }

        RowLayout {
            Text { text: "Bar position"; color: Theme.onSurface; font.pixelSize: Theme.fontSizeMd; Layout.fillWidth: true }
            ComboBox {
                model: ["top", "bottom"]
                currentIndex: Config.options.barPosition === "bottom" ? 1 : 0
                onActivated: Config.options.barPosition = currentText
            }
        }

        ToggleRow {
            label: "Dock"
            description: "Pinned apps dock at the bottom of the screen."
            checked: Config.options.dockEnabled
            onToggled: newState => Config.options.dockEnabled = newState
        }

        ToggleRow {
            label: "Desktop icons"
            description: "Show ~/Desktop files on the desktop, Windows-style. Double-click opens."
            checked: Config.options.desktopIconsEnabled
            onToggled: newState => Config.options.desktopIconsEnabled = newState
        }

        RowLayout {
            Text { text: "Time format"; color: Theme.onSurface; font.pixelSize: Theme.fontSizeMd; Layout.fillWidth: true }
            ComboBox {
                model: ["24h", "12h"]
                currentIndex: Config.options.timeFormat === "12h" ? 1 : 0
                onActivated: Config.options.timeFormat = currentText
            }
        }

        SectionTitle { text: "Text size" }

        RowLayout {
            Layout.fillWidth: true
            Slider {
                id: textScaleSlider
                from: 0.85; to: 1.5; stepSize: 0.05
                value: Config.options.textScale
                Layout.fillWidth: true
                onMoved: Config.options.textScale = value
            }
            Text {
                text: Math.round(Config.options.textScale * 100) + "%"
                color: Theme.onSurfaceVar
                Layout.preferredWidth: 44
            }
        }

        SectionTitle { text: "System themes" }

        RowLayout {
            spacing: Theme.spaceMd
            Button { text: "GTK / icons (nwg-look)"; onClicked: Quickshell.execDetached(["nwg-look"]) }
            Button { text: "Qt (Kvantum)"; onClicked: Quickshell.execDetached(["kvantummanager"]) }
            Button { text: "Cursor & fonts (HyDE)"; onClicked: Quickshell.execDetached(["hyde-shell", "theme.select"]) }
        }

        Item { Layout.preferredHeight: Theme.spaceXl }
    }
}
