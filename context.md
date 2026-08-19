# Context for the next Claude, read this first

Orientation for this machine. The *rules* for how to work live in `CLAUDE.md`
(global) and `~/.claude/projects/-home-suji/memory/MEMORY.md` (past incidents).
This file is the *terrain*: what the machine is, where things live, and which
parts have a history of surprising people.

Everything below was verified on the machine on **2026-08-19**. If something here
disagrees with what you observe, trust the machine and fix this file.

## Who

- **Soejii** (`ninkaishou27@gmail.com`), Flutter/mobile dev plus academic research.
  Work org `sidigs-id`. Writes Indonesian, wants replies in English.
- Timezone WIB. College semester starts late Aug 2026, so expect PDF-heavy work.

## Hardware and OS

Arch Linux, kernel **6.18 LTS**, Hyprland **0.56** (Lua config, not hyprlang).

- Ryzen 7 5700X, 32GB DDR4, **RX 9060 XT** (Navi 44, RDNA4, all AMD).
- Displays: **DP-1** = MSI MAG 275QF, 2560x1440@180, primary, at `0x0`.
  **HDMI-A-1** = 1080p@100 at `2560x0`. These connector names are correct;
  older notes called them guesses.
- Disks: `nvme0n1` = system (btrfs root, `/boot` vfat).
  `nvme1n1` = **btrfs, label `Games`, mounted at `/mnt/adata`**. Steam library
  lives there.
- Display manager is **SDDM**. Not LightDM, which breaks Hyprland input.

## Layout

| Path | What |
|---|---|
| `~/CODE` | 34 repos. SIDIGS Flutter apps: `nakula`, `chiron`, `gaia`, `icarus`, `arjuna`, `karna` |
| `~/CODE/KEYSTORE` | Android signing keys plus a GCP service account json. **Irreplaceable, never leak** |
| `~/.dotfiles` | Bare git repo, work tree is `$HOME`, branch `desktop`, remote `Soejii/dotfiles` |
| `~/.claude` | Claude Code config, skills, agents, memory |
| `~/.local/bin` | Hand written tooling (`cockpit`, `flutter-analyze-diff`, watchdogs, recovery scripts) |

The dotfiles repo takes an explicit git dir on every command, and
`status.showUntrackedFiles` is off, so only tracked files ever appear:

```bash
git --git-dir=$HOME/.dotfiles --work-tree=$HOME <cmd>
```

## Subsystems with a history

Do not rediscover these. Each has a memory file with the full diagnosis; read it
before you touch the area.

- **Idle, lock and suspend.** hypridle, a watchdog timer, and hyprlock interact
  badly and have caused three separate incidents. `hyprctl dispatch dpms` is a
  broken no-op under Lua, and it toggles, so never live test it.
- **Audio.** Chromium and Electron apps drive the *hardware* capture mixer, which
  drags the mic down for every other app. Fixed with PipeWire's
  `block-source-volume` quirk in `~/.config/pipewire/pipewire-pulse.conf.d/`.
- **Networking.** Mudfish Full VPN kills the IPv4 default route and looks like a
  machine that needs a reboot. Use Item mode. Recovery script exists.
- **Delegation.** Implementation goes to opencode workers through `cockpit`,
  default model family **Luna**. Older notes say deepseek/gemini; that is wrong now.
- **Streaming.** OBS is the Flatpak build, config at `~/.config/obs-studio`, with
  `~/.var/app` symlinked to it. GG Strive stream tooling in `~/CODE/strive-stream`.

## Automation

Five systemd **user** timers. They need `loginctl enable-linger`.

- `appsheet-daily`, `appsheet-presensi`, `aktivo-keluar`: work automation, needs
  its `.env` and `npx playwright install chromium`.
- `claude-ping`: anchors the rolling Claude usage window. Uses a long lived
  `setup-token`, never an API key, because that would bill per token.
- `hypridle-watchdog`: guards the idle stack described above.

Systemd status alone is not proof any of these worked. Read their logs.

## Historical note

This file used to be a migration runbook for the Windows 11 to Arch move of June
2026. That migration is **finished**. The backup disk it described has since been
reformatted to btrfs for games, so its recovery instructions would now be actively
misleading. Both of its outstanding security items are closed: the KEYSTORE is
restored, and no GitHub token remains embedded in any remote URL in `~/CODE`.

`ARCH-SETUP.md` in this repo is from the same era and is likewise historical. Keep
it for reference, do not execute it.
