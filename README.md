# HamadaOS v3 — The Gaming Desktop

> CachyOS + HyDE + Hyprland + **Quickshell** → a unified, Windows-replacing desktop
> where every pixel is managed from one UI and every color flows from your wallpaper.

## Quick install — ONE command from bare CachyOS

```bash
git clone https://github.com/hamad/hamadaos-dots.git ~/hamadaos-dots
cd ~/hamadaos-dots && ./install.sh
```

That's everything: installs HyDE itself if missing, detects your AUR helper
(or bootstraps yay), installs every package with per-package fault tolerance
(one broken AUR package never kills the run — failures are listed at the end
with a retry command), links every config, profiles your hardware, enables
every service. Re-running is always safe.

After reboot: **Settings → Health** is your "is everything working?" button —
one click runs ~45 system checks, one click auto-fixes what's fixable, and
the same page shows pending updates from CachyOS repos, AUR, HyDE, and
hamadaos-dots with an "Update everything" button. (Launcher: type
"troubleshoot" or "windows update".)

## Test it in a VM first (fully supported)

HamadaOS detects virtualization and reconfigures its graphics stack
automatically — software cursors, explicit-sync off, llvmpipe fallback when
the VM has no 3D acceleration. The same dots boot unmodified on bare metal
and in VMware/VirtualBox/KVM/Hyper-V. Full playbook with hypervisor settings,
an SSH-driven verification workflow, and an 11-point test checklist:
[docs/VM-TESTING.md](docs/VM-TESTING.md).

## If anything ever breaks

- **Safe Mode** at the login screen — a minimal session that sources nothing
  (no plugins, no shell, no theme) and therefore always boots, opening a
  rescue menu: auto-fix, export logs for help, disable plugins, reset shell
  settings, re-link configs, guided snapshot rollback, or just update.
- **Updates are previewed and reversible**: "Update everything" first shows
  exactly what it will touch (package list, HyDE/dots commits), asks for
  confirmation, then takes a Btrfs snapshot AND a settings backup before
  changing anything. Roll the system back from Safe Mode in one command.
- **Export my settings** (Settings → Tools or launcher: "backup") packs your
  shell config, display layout, per-game overrides, HyDE overrides, and GPU
  profiles into one tar.gz — restore it on any HamadaOS machine.

## First run

A welcome screen picks your app suite (browser, office, media, chat — 
installed on the spot) and teaches the three keybinds that matter. Settings →
Tools is the Windows "Administrative Tools" answer: disks, device info, event
viewer, services, network tools, printers, snapshots — plus a **controller
center** (Xbox/DualSense pair via Bluetooth with battery readout; paddles and
gyro work out of the box via game-devices-udev).

## What makes this different

**One process renders the entire shell.** Quickshell (QML) replaces Waybar,
dunst, and wlogout with a single application: bar, dock, launcher, control
center, notifications, volume/brightness OSD, power menu, and a full Settings
app — all sharing one design-token system (`Theme.qml`) and one settings store
(`~/.config/hamadaos/config.json`). Change anything, everything updates in the
same frame.

**The shell IS the notification daemon.** Quickshell registers
`org.freedesktop.Notifications` natively — every notify-send, Discord ping,
and browser alert renders as a HamadaOS banner with working action buttons.

**Wallpaper drives everything, the HyDE-native way.** We don't replace HyDE's
wallpaper pipeline — we extend it through Wallbash's documented hook
(`wallbash/always/hamadaos.dcol` → `wallbash/scripts/hamadaos.sh`):

```
HyDE sets wallpaper → Wallbash extracts colors → hamadaos.sh runs matugen
  → GeneratedColors.qml  (Quickshell hot-reloads, same frame)
  → hypr/themes/colors.conf + hyprbars-colors.conf  (borders, title bars)
  → GTK3/GTK4 CSS · Kvantum (Qt) · kitty (live socket reload) · VS Code
```

**Native service bindings, no polling.** Audio is live PipeWire objects,
battery is UPower, Bluetooth is BlueZ, MPRIS is real D-Bus players, network
refreshes on `nmcli monitor` events. The bar idles at ~0% CPU.

**Gaming mode is one keypress** (`Super+Shift+G`): HyDE's gaming workflow
(blur/shadows/animations off) + performance CPU governor + TuneD throughput
profile + fullscreen-only VRR — passwordless via a sudoers drop-in scoped to
exactly two whitelisted commands.

**Windows muscle memory works.** Search the launcher for what you'd search on
Windows — *device manager*, *control panel*, *task manager*, *disk management*,
*add or remove programs*, *snipping tool*, *system restore*, *windows hello*,
*nvidia control panel*, *mobile hotspot* — and the right tool opens. Settings
has Windows-grade pages: per-monitor resolution/refresh/scale with "Save
layout" (3-monitor friendly), Default Apps (browser, players, mail — applied
system-wide via XDG), and fingerprint enrollment/removal. Desktop icons render
`~/Desktop` natively in Quickshell — double-click to open, themed by your
wallpaper like everything else.

## The performance stack (weak-GPU laptops are the target)

One line in Steam launch options activates all of it, on any machine:

```
hamadaos-game-run %command%
```

The wrapper reads a hardware profile generated at install
(`hamadaos-hw-profile.sh` → GPU vendor, Optimus, VRAM, ReBAR, RAM,
TDP-shared chassis) and applies only what helps *that* machine:

| Machine | What it does |
|---|---|
| Optimus laptop (MX350 Zenbook) | PRIME render offload — game on dGPU, desktop composites on iGPU |
| ≤4.5GB VRAM (MX350, 3050) | DXVK small-chunk allocation + VKD3D `no_upload_hvv` (no ReBAR → don't fight textures for the BAR window) |
| NVIDIA | Persistent shader cache, never cleaned → second run has zero compile stutter |
| AMD/Intel (Mesa) | glthread + 12GB shader cache |
| All | GameMode, optional MangoHud, optional **gamescope FSR** from Settings → Gaming (render 75%, upscale — the weak-GPU superpower) |

**Gaming mode flips automatically** when any game starts (GameMode hooks),
or manually with `Super+Shift+G`: HyDE gaming workflow (effects off),
`scx_lavd` latency scheduler, performance governor, THP=always, PCIe ASPM off,
**MGLRU working-set lock** (`min_ttl_ms=3000` — the fix for "45fps then
sudden 8fps": the kernel was evicting the game's hot pages under memory
pressure), plus zram-correct swap tuning (`swappiness=150`, `page-cluster=0`).

On TDP-shared thin laptops there's a **GPU priority** toggle (Settings →
Gaming) that caps CPU turbo while gaming — on a 40W RTX 3050 or an MX350
ultrabook, the package watts the CPU stops burning go to the GPU instead,
which frequently *raises* fps. `nvidia-powerd` (Dynamic Boost) is enabled
automatically on NVIDIA hybrid laptops.

**Honest expectations:** OS tuning buys roughly 10–25% average fps over a
stock setup plus dramatically flatter frametimes; FSR upscaling at 75% buys
another 30–60% at minor visual cost. What it cannot do is make a 2GB-VRAM
GPU hold high-texture settings — drop textures to Low/Medium on the MX350 and
let the stack do the rest. Where this *beats* Windows is consistency: no
background services stealing frames, no sudden 8fps memory-pressure cliffs,
no shader recompile hitching after driver updates.

### Dynamic control & measurement

- **Overclocking** — LACT (`lactd` daemon enabled at install) is the MSI
  Afterburner equivalent: clock offsets, fan curves, power limits, per-game
  profiles. Search "msi afterburner" in the launcher. NVIDIA offsets need
  driver 555+ (RTX 3050 ✓; MX350/Pascal exposes power/fan only — a driver
  limit, not ours).
- **Thermal guard** — runs automatically with gaming mode on laptops. Watches
  GPU/CPU temps *and the driver's real throttle reasons*; before the firmware
  cliff it caps CPU turbo (watts → GPU), and de-escalates with 8°C hysteresis
  so it never flaps. Desktops: exits instantly.
- **Telemetry** — `hamadaos-bench.sh start/stop/report`: MangoHud frametime
  capture + 1Hz GPU clock/temp/throttle sampling → average fps, 1% and 0.1%
  lows, 99th-percentile frametime, throttle-second counts. Change one thing,
  re-measure. Sessions archive to `~/.local/share/hamadaos/bench/`.
- **Per-title policy** — `~/.config/hamadaos/games.d/<AppID>.env` overrides
  the wrapper per game (NTSync, DXVK frame caps, VKD3D flags…). The Finals
  example ships ready to copy.

### Screenshare that actually works (the Discord problem)

Three separate bugs hide behind "Discord share is broken on Linux":

1. **Black screen** → official Discord can't do Wayland portal capture.
   HamadaOS ships **Vesktop** (search "discord" in the launcher): proper
   PipeWire capture *plus* audio sharing, which Discord-on-Linux never had.
2. **fps loss while sharing** → the portal config (`xdph.conf`) caps capture
   at 60fps and keeps it on the zero-copy DMA-BUF path; Discord still
   software-encodes the stream, so share at 720p30 on weak laptops — or use
   OBS with NVENC/VAAPI for real streaming.
3. **Tearing the moment a share starts** → gaming mode enables immediate
   page-flips, and screencopy + tearing produce torn frames on both your
   screen and the stream. The **Screenshare Guard** listens for Hyprland's
   `screencast` event and reconfigures the compositor live: tearing and VRR
   off while any capture is active, restored the second it stops. Windows
   can't do this — apps there can't reconfigure the compositor per-capture.

### MUX-less hybrid laptops (Intel/AMD iGPU + NVIDIA dGPU)

No MUX switch means the panel is wired to the iGPU and every dGPU frame
crosses PCIe. The stack attacks every controllable step:

- **Compositor pinned to the iGPU** — the profiler maps `/dev/dri/card*` by
  driver and writes an explicit `AQ_DRM_DEVICES` ordering. If Hyprland
  accidentally composites on the dGPU (common!), every desktop frame
  double-copies and the dGPU can never sleep. This one line is the biggest
  silent win on hybrids.
- **Games offload to the dGPU** — PRIME env from `hamadaos-game-run`.
- **Direct scanout in gaming mode** — the fullscreen game buffer goes
  straight to the display engine, skipping a composition pass (one less
  PCIe copy per frame).
- **dGPU runtime D3 power-gating** — modprobe + udev rules (installed only
  when an NVIDIA hybrid is detected): the dGPU is fully OFF outside games,
  so its watts and heat exist only while playing. On a 40W chassis that
  power budget goes back to sustained boost clocks.

### Bluetooth headsets (the "mic ruins the audio" fix)

Bluetooth physically can't do hi-fi stereo (A2DP) and a microphone at once —
the moment Discord opens your headset mic, the headset falls back to the HFP
profile, and classic HFP is 8kHz telephone audio. HamadaOS ships a
WirePlumber config that makes this as good as the protocol allows:

- **mSBC** — 16kHz wideband HFP: voice-clear instead of walkie-talkie
- **SBC-XQ** — higher-bitrate A2DP for the music/game side
- **LE Audio (LC3/BAP)** roles enabled — headsets that support it get good
  quality *with* mic simultaneously; this is the real long-term fix
- **The pro move**: in Settings → Sound, pick **Internal Microphone** as the
  input and leave the headset on A2DP — full-quality audio AND a working mic
  with zero profile switching. For competitive play this beats every codec.

PipeWire also gets a 512-sample quantum floor: the popular "lower quantum =
better" advice is backwards on weak CPUs — tiny quanta mean thousands of
extra audio wakeups per second stolen from the game (that's the Discord
crackle in team fights).

### What we deliberately did NOT do (and why)

Tuning folklore that *loses* fps on this hardware, rejected on purpose:

| Technique | Why it's out |
|---|---|
| PREEMPT_RT kernel | Trades throughput for determinism — games measurably lose fps. RT is for robots and audio, not renderers. scx_lavd gives the latency win without the cost. |
| `isolcpus` / `nohz_full` core isolation | Removes cores from the scheduler; modern games are 8+ threads on a 4-core laptop. Starves the game it's meant to help. |
| `cpuidle.off` / `max_cstate=0` | Burns idle watts → on a TDP-shared 40W laptop those watts come straight out of the GPU budget. We do the opposite (cap CPU boost). |
| "Clone NVIDIA power tables" | Not a thing on Linux laptops — vBIOS power limits are signed. LACT exposes everything the driver legally allows (including manual clock locks, per-profile). |
| Homebrew "ML shader prediction" | Valve already ships the production version: fossilize / Steam Shader Pre-Caching replays pipeline creation before launch. Keep it ON; don't reinvent it worse. |
| Compositor input buffering | Adds a frame of latency *by definition* — the opposite of what a shooter needs. |
| X11-vs-Wayland auto-switching | Obsolete: NVIDIA 555+ explicit sync closed the Wayland gap, and gamescope already gives each game its own clean XWayland surface. |
| Flatpak Steam "for isolation" | Isolation ≠ performance — it adds portal hops and breaks our wrapper's env passing. Native Steam + pressure-vessel is already containerized. |
| Disabling the Steam runtime | Not optional anymore; games link against it. Breaking it breaks games, saves nothing. |
| `nice -19` on audio | Backwards: starved audio threads *cause* crackling. PipeWire runs real-time via rtkit on purpose; we raise the quantum floor instead. |
| Global `blockdev --setra` bumps | Helps sequential reads, hurts the random reads games actually do. CachyOS already mounts btrfs `noatime`. |
| `xinput` / evdev raw-input tricks | X11-era advice — Wayland already reads evdev directly. The real fix is `accel_profile = flat` (shipped). |
| `input_latency = 0` | Not a Hyprland option that exists. Tearing + direct scanout (shipped) are the real latency levers. |
| UMA Frame Buffer BIOS tweak | Only matters for iGPU-*gaming* (AMD APUs). On our dGPU laptops the iGPU just composites — stealing 1GB from an 8GB machine makes the memory cliff *worse*. APU owners: yes, set 1–2GB in BIOS. |

## App compatibility — the honest table

Settings → **Compatibility** runs live tests on your hardware and sets these up:

| You need | What you get | Honest status |
|---|---|---|
| Microsoft Office | M365 web apps as PWAs via native Edge — own windows, your account, OneDrive, co-editing. Launcher: "word", "excel" | **Works 100%** (it's Microsoft's runtime). Desktop binaries under Wine: **impossible** (Click-to-Run; CrossOver can't either). VBA/COM add-ins → WinApps (hidden VM, opt-in) |
| Logitech G HUB | Piper writes DPI/buttons/RGB to the mouse's **onboard memory** (same memory G HUB uses — profiles persist daemon-free); Solaar for receivers/battery; HeadsetControl for G headsets. Launcher: "g hub" | **Hardware fully controllable.** The G HUB binary itself can't run (Windows kernel drivers) — and isn't needed |
| Local .docx/.xlsx | LibreOffice (installed) round-trips Office formats | Good, not pixel-identical for complex layouts |
| Windows .exe apps | Bottles (per-app Wine prefixes, dependency auto-install) | Most apps work; check WineHQ AppDB per app |
| Multiplayer games | Proton-GE preconfigured; EAC/BattlEye work when the developer enables Linux | Check areweanticheatyet.com per title before promising a friend |

One testing caveat, stated plainly: this repo was built and verified on a
Windows machine — file-level correctness only. The Compatibility page and
`hamadaos-doctor.sh` exist precisely so that *your* first boot proves each
claim on *your* hardware (does ratbagd see your G502, do the PWAs launch)
before you bet your daily driver on it.

## Keybinds

| Key | Action |
|-----|--------|
| `Super+Space` | App launcher (type → Enter) |
| `Super+I` | Settings app |
| `Super+C` | Control center |
| `Super+Tab` | Task overview (live workspaces) |
| `Super+Grave` | hyprexpo workspace grid |
| `Alt+Tab` | Visual window switcher (hyprswitch) |
| `Super+←/→/↑/↓` | Snap left/right · maximize · minimize |
| `Super+Alt+arrows` | Quarter snapping (FancyZones) |
| `Ctrl+Shift+Esc` | Task manager (Mission Center) |
| `Ctrl+Alt+Del` | Power menu |
| `Super+Shift+G` | Gaming mode |
| `Super+Shift+T` | OCR — copy text from screen (eng+ara) |
| `Super+V` | Clipboard history |
| `Ctrl+Alt+1` | ZoomIt — toggle 2× zoom (`Ctrl+Alt+=`/`-` to step) |
| `Ctrl+Alt+2` | ZoomIt — draw on screen (`Ctrl+Alt+3` clears) |
| `Win+Space` | English ↔ Arabic keyboard |

## Repo layout

```
config/
  quickshell/        the entire shell (QML) — see modules/*
  hypr/              HyDE-safe overrides: userprefs, windowrules (0.53 syntax
                     + legacy fallback), keybindings, plugins, animations preset
  hyde/              config.toml override + the Wallbash→matugen bridge
  matugen/           templates: QML, GTK3/4, Kvantum, kitty, VS Code, Hyprland
scripts/             gaming-mode, snap-quarter, OCR, wallpaper, doctor, setup-*
system/              sysctl, zram, file limits, sudoers drop-in, governor helper
```

## Design decisions worth knowing

- **HyDE files are never overwritten.** Everything installs to HyDE's
  documented user-override points (`~/.config/hypr/*`, `~/.config/hyde/*`).
  HyDE updates can't break HamadaOS; HamadaOS can't break HyDE.
- **Settings persist outside the repo** (`~/.config/hamadaos/config.json`),
  so the dotfiles stay clean in git. `GeneratedColors.qml` is the one
  matugen-written file in-repo — it ships Catppuccin Mocha defaults so the
  shell looks right before the first wallpaper.
- **Window rules use the Hyprland ≥0.53 grammar** HyDE v26 targets, wrapped
  in `# hyprlang if HYPRLAND_V_0_53` guards with a `windowrulev2` fallback.
- **Night light = hyprsunset** (HyDE already runs it; we drive it over
  `hyprctl hyprsunset`), not a second daemon.

## Troubleshooting

`~/.config/hypr/scripts/hamadaos-doctor.sh` checks the whole stack: packages,
running daemons, IPC registration, plugins, notification ownership, file
limits, fonts, and the theming pipeline — and tells you the fix for anything
red.
