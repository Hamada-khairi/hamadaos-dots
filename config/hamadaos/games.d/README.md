# Per-title overrides

Drop `<SteamAppID>.env` or `<executable>.env` files here. They're sourced by
`hamadaos-game-run` after the automatic hardware tuning, so anything you set
wins for that one game. Find the AppID in the game's Steam store URL.

Useful knobs:

```bash
# NTSync — kernel-native Windows sync primitives (CachyOS kernels ship the
# module). Proton 9+/GE: often better lows in CPU-heavy multiplayer titles.
PROTON_USE_NTSYNC=1

# Frame cap at the DXVK level (smoother than in-game limiters in some titles)
DXVK_FRAME_RATE=60

# Force a different VKD3D feature level if a DX12 game refuses to start
VKD3D_FEATURE_LEVEL=12_1

# Disable our low-VRAM no_upload_hvv heuristic for a specific game
VKD3D_CONFIG=

# Larger Wine shared memory for stutter-prone titles
STAGING_SHARED_MEMORY=1

# Rare titles that regress with fsync — fall back to esync for that game only
PROTON_NO_FSYNC=1
```

Two Steam settings worth knowing (per-game, in Steam itself):
- **Shader Pre-Caching: ON** (Steam → Settings → Downloads) — Valve's
  fossilize system pre-compiles pipelines before launch. This is the real,
  production version of "ML shader prediction" — keep it enabled.
- **Steam Overlay: OFF** for weak GPUs (game → Properties) — the overlay
  costs a few percent on 2GB-VRAM cards; re-enable where you need it.

Example — `the-finals.example.env` ships next to this file; copy it to the
real AppID to activate:

```bash
cp the-finals.example.env 2073850.env
```
