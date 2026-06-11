# Testing HamadaOS in a VM — the full playbook

HamadaOS is VM-aware: the hardware profiler runs `systemd-detect-virt`, and
when it finds a hypervisor it rewrites the graphics strategy automatically —
software cursors (VMs have no hardware cursor plane), explicit-sync off (VM
DRM drivers fake their fences), `Virtual-1` preferred mode, and full llvmpipe
CPU-rendering fallback with blur/shadows disabled when no 3D render node
exists. **The same dotfiles, untouched, boot on bare metal and in a VM.**

## 1. Host setup (pick your hypervisor)

The single thing that decides whether Hyprland feels usable in the VM is
**3D acceleration**. Enable it:

| Hypervisor (on Windows) | Settings that matter |
|---|---|
| **VMware Workstation Player** (recommended on Windows — free) | Display → ☑ *Accelerate 3D graphics*, 8GB graphics memory. Gives `vmwgfx` DRM with GL — Hyprland runs accelerated. |
| **VirtualBox** | Display → VMSVGA + ☑ *Enable 3D Acceleration*. Hit-or-miss with Wayland; if Hyprland glitches, HamadaOS's llvmpipe fallback still boots it. |
| **Hyper-V** | No guest 3D for Linux DRM — HamadaOS auto-falls back to llvmpipe. Works, but animations are CPU-drawn; fine for functional testing only. |
| **QEMU/KVM** (if testing from another Linux box) | Video `virtio` + 3D acceleration ON (`virtio-gpu-gl`). The best option overall. |

VM sizing: 4+ cores, 8GB RAM, 60GB disk, EFI firmware, **btrfs** in the
CachyOS installer (snapshots are part of what we're testing).

## 2. Install CachyOS, then HamadaOS — one command

In the VM, after CachyOS first boot:

```bash
sudo pacman -S --needed git openssh
git clone <your-hamadaos-dots-repo> ~/hamadaos-dots
cd ~/hamadaos-dots && ./install.sh        # installs HyDE too if missing
```

## 3. Let the assistant drive the tests over SSH

This is the "actually verify it" step. In the VM:

```bash
sudo systemctl enable --now sshd
ip addr show | grep "inet "        # note the VM's IP (e.g. 192.168.122.50)
```

In VMware/VirtualBox use a *Bridged* or *NAT with port-forward* network so the
Windows host can reach the VM. Then from the Windows side, Claude can run the
whole verification hands-on:

```powershell
ssh user@<vm-ip> "~/.config/hypr/scripts/hamadaos-doctor.sh"
ssh user@<vm-ip> "~/.config/hypr/scripts/hamadaos-doctor.sh --fix"
ssh user@<vm-ip> "cat ~/.config/hamadaos/hardware.env"   # IS_VM=1 expected
ssh user@<vm-ip> "cat ~/.config/hypr/gpu.conf"           # VM profile expected
```

Inside the graphical session (login as the user, pick "Hyprland"), the
remaining GUI checks:

## 4. The test checklist

| # | Test | Pass looks like |
|---|---|---|
| 1 | Login → Hyprland session starts | Bar appears, no error popups |
| 2 | `hardware.env` | `IS_VM=1`, correct `VIRT_TYPE`, `VM_HAS_3D` matches host setting |
| 3 | Doctor (Settings → Health → Check) | VM section green; "VM graphics profile applied" ✓ |
| 4 | Super+Space → type "control panel" | Settings opens (Windows-name aliases work) |
| 5 | Notifications: `notify-send hello world` | HamadaOS banner appears (we ARE the daemon) |
| 6 | Wallpaper change | Entire desktop recolors in ~2s (bar, terminal, borders) |
| 7 | Title bars | Min/max/close on the right of every floating window |
| 8 | **Office**: Settings → Compatibility → Set up Office → Word | Word opens in its own window; sign in; type a doc; it saves to OneDrive |
| 9 | Safe Mode: log out → pick "HamadaOS (Safe Mode)" | Rescue menu boots even after `mv ~/.config/quickshell ~/.config/quickshell.bak` (put it back after!) |
| 10 | Updates: Health → Update everything | Preview shows package list, asks confirmation, snapshots first |
| 11 | First-run: `rm ~/.config/hamadaos/config.json` + relog | Welcome window appears once |

## 5. What a VM CANNOT validate (don't draw conclusions)

- **Gaming performance** — no real GPU. FSR, gamescope, VRR, tearing,
  MangoHud numbers: bare metal only (the USB-NVMe boot drive is the right
  tool for that).
- **Logitech onboard profiles** — USB passthrough of the receiver to the VM
  works in VMware/VirtualBox and *does* let you test Piper end-to-end if you
  want (pass the "Logitech USB Receiver" device through, then Piper should
  list the mouse).
- **Thermal guard, TDP logic, NVIDIA paths** — all hardware-gated; they
  correctly no-op in the VM (the doctor will show them skipped, which is
  itself a pass for the detection logic).

## 6. About "Office 2024" specifically

The desktop Office 2024 installer will not run under Wine in the VM (or
anywhere on Linux) — testing it would only re-prove the documented blocker.
What the VM *does* prove end-to-end: the Edge-PWA pipeline (test #8) — real
Microsoft account, real documents, real OneDrive sync. If the verdict after
test #8 is "this isn't enough Office for me," the decision data is: WinApps
(real binaries, hidden VM) or staying dual-boot for Office — and the VM test
told you that *before* you wiped anything.
