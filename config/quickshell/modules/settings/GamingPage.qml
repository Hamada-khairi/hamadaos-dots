// HamadaOS Settings — Gaming (real Proton detection, no toggle loops)
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.services

Flickable {
    id: root
    contentHeight: col.implicitHeight
    clip: true

    property var protonVersions: []

    Component.onCompleted: protonScan.running = true

    Process {
        id: protonScan
        command: ["sh", "-c",
            "ls -1 ~/.steam/root/compatibilitytools.d 2>/dev/null; " +
            "ls -1d ~/.local/share/Steam/steamapps/common/Proton* 2>/dev/null | xargs -rn1 basename"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.protonVersions = text.trim() === "" ? [] : text.trim().split("\n")
            }
        }
    }

    ColumnLayout {
        id: col
        width: root.width
        spacing: Theme.spaceLg

        SectionTitle { text: "Performance" }

        ToggleRow {
            label: "Gaming Mode"
            description: "HyDE gaming workflow (no blur/shadows/animations) + performance CPU governor + tuned throughput profile + fullscreen-only VRR."
            checked: GamingService.active
            onToggled: GamingService.toggle()
        }

        ToggleRow {
            label: "MangoHud overlay"
            description: "FPS, frametime, temps — applied by the HamadaOS launcher below."
            checked: Config.options.mangoHudEnabled
            onToggled: newState => Config.options.mangoHudEnabled = newState
        }

        ToggleRow {
            label: "GPU priority (thin laptops)"
            description: "On TDP-shared laptops (40W RTX 3050, MX-series ultrabooks), caps CPU turbo while gaming so the package power flows to the GPU. Often RAISES fps on these machines."
            checked: Config.options.gpuPriority
            onToggled: newState => Config.options.gpuPriority = newState
        }

        SectionTitle { text: "FSR Upscaling (gamescope)" }

        ToggleRow {
            label: "Render lower, upscale with FSR"
            description: "The weak-GPU superpower: render at a fraction of your resolution, AMD FSR upscales it back. Works on ANY GPU including NVIDIA."
            checked: Config.options.gamescopeEnabled
            onToggled: newState => Config.options.gamescopeEnabled = newState
        }

        ColumnLayout {
            visible: Config.options.gamescopeEnabled
            Layout.fillWidth: true
            spacing: Theme.spaceSm

            RowLayout {
                Text { text: "Output"; color: Theme.onSurface; font.pixelSize: Theme.fontSizeSm; Layout.preferredWidth: 110 }
                ComboBox {
                    model: ["1280×720", "1600×900", "1920×1080", "2560×1440"]
                    currentIndex: {
                        const h = Config.options.gamescopeOutH
                        return h <= 720 ? 0 : h <= 900 ? 1 : h <= 1080 ? 2 : 3
                    }
                    onActivated: index => {
                        const dims = [[1280,720],[1600,900],[1920,1080],[2560,1440]][index]
                        Config.options.gamescopeOutW = dims[0]
                        Config.options.gamescopeOutH = dims[1]
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Render scale"; color: Theme.onSurface; font.pixelSize: Theme.fontSizeSm; Layout.preferredWidth: 110 }
                Slider {
                    from: 50; to: 100; stepSize: 5
                    value: Config.options.gamescopeScale
                    Layout.fillWidth: true
                    onMoved: Config.options.gamescopeScale = Math.round(value)
                }
                Text {
                    text: Config.options.gamescopeScale + "% → "
                        + Math.round(Config.options.gamescopeOutW * Config.options.gamescopeScale / 100) + "×"
                        + Math.round(Config.options.gamescopeOutH * Config.options.gamescopeScale / 100)
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSizeXs
                    color: Theme.primary
                }
            }

            RowLayout {
                Text { text: "FPS cap"; color: Theme.onSurface; font.pixelSize: Theme.fontSizeSm; Layout.preferredWidth: 110 }
                ComboBox {
                    model: ["Uncapped", "30", "40", "60", "90", "120"]
                    currentIndex: {
                        const v = Config.options.gamescopeFpsCap
                        const map = [0, 30, 40, 60, 90, 120]
                        const i = map.indexOf(v)
                        return i >= 0 ? i : 0
                    }
                    onActivated: index =>
                        Config.options.gamescopeFpsCap = [0, 30, 40, 60, 90, 120][index]
                }
                Text {
                    text: "Capping near your average fps = flat frametimes"
                    font.pixelSize: Theme.fontSizeXs
                    color: Theme.onSurfaceVar
                }
            }
        }

        SectionTitle { text: "Steam launch options" }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: launchText.implicitHeight + Theme.spaceMd * 2
            radius: Theme.radiusMd
            color: Theme.surface2

            Text {
                id: launchText
                anchors { fill: parent; margins: Theme.spaceMd }
                text: "hamadaos-game-run %command%"
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeSm
                color: Theme.colorSuccess
            }
        }
        RowLayout {
            Button {
                text: "Copy"
                onClicked: Quickshell.execDetached(["sh", "-c",
                    "printf '%s' 'hamadaos-game-run %command%' | wl-copy"])
            }
            Text {
                Layout.fillWidth: true
                text: "One wrapper, every machine: detects Optimus, low VRAM, ReBAR — applies PRIME offload, shader caches, FSR, GameMode automatically."
                font.pixelSize: Theme.fontSizeXs
                color: Theme.onSurfaceVar
                wrapMode: Text.WordWrap
            }
        }

        SectionTitle { text: "Proton" }

        Text {
            visible: root.protonVersions.length === 0
            text: "No Proton versions found yet — install Steam and proton-ge-custom-bin."
            font.pixelSize: Theme.fontSizeSm
            color: Theme.onSurfaceVar
        }

        Repeater {
            model: root.protonVersions
            Text {
                required property string modelData
                text: "•  " + modelData
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeSm
                color: Theme.onSurface
            }
        }

        Text {
            text: "Per-game Proton selection lives in Steam → Properties → Compatibility."
            font.pixelSize: Theme.fontSizeXs
            color: Theme.onSurfaceVar
        }

        SectionTitle { text: "Overclocking (MSI Afterburner equivalent)" }

        RowLayout {
            spacing: Theme.spaceMd
            Button { text: "Open LACT"; onClicked: Quickshell.execDetached(["lact"]) }
            Button { text: "CoreCtrl"; onClicked: Quickshell.execDetached(["corectrl"]) }
        }
        Text {
            Layout.fillWidth: true
            text: "LACT = core/memory clock offsets, fan curves, power limits, per-game profiles. " +
                  "Your Windows +200 core / +800 mem workflow lives here. " +
                  "NVIDIA clock offsets need driver 555+ (RTX 3050: yes; MX350/Pascal: power & fan only — offsets aren't exposed by NVIDIA's Linux driver for that generation)."
            font.pixelSize: Theme.fontSizeXs
            color: Theme.onSurfaceVar
            wrapMode: Text.WordWrap
        }

        SectionTitle { text: "Benchmark — measure, don't guess" }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: benchText.implicitHeight + Theme.spaceMd * 2
            radius: Theme.radiusMd
            color: Theme.surface2
            Text {
                id: benchText
                anchors { fill: parent; margins: Theme.spaceMd }
                text: "hamadaos-bench.sh start   →  play 5 min  →  hamadaos-bench.sh stop"
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeSm
                color: Theme.colorSuccess
            }
        }
        Text {
            Layout.fillWidth: true
            text: "Reports average fps, 1% / 0.1% lows, 99th-percentile frametime, GPU clocks, and the driver's actual throttle reasons. Change one setting, re-run, compare. The thermal guard also runs automatically in gaming mode on laptops — it caps CPU turbo before the firmware throttle cliff hits."
            font.pixelSize: Theme.fontSizeXs
            color: Theme.onSurfaceVar
            wrapMode: Text.WordWrap
        }

        SectionTitle { text: "Tools" }

        RowLayout {
            spacing: Theme.spaceMd
            Button { text: "MangoHud editor (GOverlay)"; onClicked: Quickshell.execDetached(["goverlay"]) }
            Button { text: "Heroic (Epic/GOG)"; onClicked: Quickshell.execDetached(["heroic"]) }
            Button { text: "Lutris"; onClicked: Quickshell.execDetached(["lutris"]) }
        }

        Item { Layout.preferredHeight: Theme.spaceXl }
    }
}
