// ═══════════════════════════════════════════════════════════════════════════════
// HamadaOS — Audio Service (native PipeWire bindings)
// ═══════════════════════════════════════════════════════════════════════════════
// Uses Quickshell.Services.Pipewire directly — no polling, no wpctl parsing.
// Volume changes from any source (hardware keys, pavucontrol, games) appear
// here instantly via PipeWire events.
//
//   sink / source        — default audio output / input (PwNode)
//   volume / muted       — live master state
//   outputAppNodes       — per-app streams for the mixer
//   outputDevices        — selectable sinks
//
// Reference: end-4/dots-hyprland services/Audio.qml
// ═══════════════════════════════════════════════════════════════════════════════

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    property bool ready: Pipewire.defaultAudioSink?.ready ?? false
    property PwNode sink: Pipewire.defaultAudioSink
    property PwNode source: Pipewire.defaultAudioSource

    property real volume: sink?.audio?.volume ?? 0
    property bool muted: sink?.audio?.muted ?? false
    property bool micMuted: source?.audio?.muted ?? false

    // Fired on volume/mute change — the OSD listens to this.
    signal volumeChangedByUser()

    // ── Node lists ──────────────────────────────────────────────────────────
    function appNodes(isSink) {
        return Pipewire.nodes.values.filter(node =>
            node.isSink === isSink && node.audio && node.isStream)
    }
    function devices(isSink) {
        return Pipewire.nodes.values.filter(node =>
            node.isSink === isSink && node.audio && !node.isStream)
    }
    readonly property list<var> outputAppNodes: root.appNodes(true)
    readonly property list<var> outputDevices: root.devices(true)
    readonly property list<var> inputDevices: root.devices(false)

    function appDisplayName(node) {
        return node.properties["application.name"] || node.description || node.name
    }
    function deviceDisplayName(node) {
        return node.nickname || node.description || node.name
    }

    // ── Controls ────────────────────────────────────────────────────────────
    function setVolume(v) {
        if (!sink?.audio) return
        sink.audio.muted = false
        sink.audio.volume = Math.max(0, Math.min(1.5, v))
        root.volumeChangedByUser()
    }

    function increment() { setVolume(Math.min(1.0, volume + 0.05)) }
    function decrement() { setVolume(Math.max(0.0, volume - 0.05)) }

    function toggleMute() {
        if (!sink?.audio) return
        sink.audio.muted = !sink.audio.muted
        root.volumeChangedByUser()
    }

    function toggleMicMute() {
        if (!source?.audio) return
        source.audio.muted = !source.audio.muted
    }

    function setAppVolume(node, v) {
        if (node?.audio) node.audio.volume = Math.max(0, Math.min(1, v))
    }

    function setDefaultSink(node) {
        Pipewire.preferredDefaultAudioSink = node
    }

    function setDefaultSource(node) {
        Pipewire.preferredDefaultAudioSource = node
    }

    // Track the default nodes so their .audio properties stay bound.
    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    // Track app streams + devices shown in mixers.
    PwObjectTracker {
        objects: [...root.outputAppNodes, ...root.outputDevices]
    }

    // Hardware keys / external changes should also flash the OSD.
    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() { root.volumeChangedByUser() }
        function onMutedChanged() { root.volumeChangedByUser() }
    }
}
