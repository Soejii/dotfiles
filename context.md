# Context for the next Claude — read this first

You are running on a **freshly installed Arch Linux desktop**, mid-migration from
Windows 11. This file is orientation. **The execution steps live in `ARCH-SETUP.md`
— read it and run it end to end.** This file tells you the *why* and *where*.

## Who / what
- User **sujia** (GitHub `Soejii`, work org `sidigs-id`). Flutter/mobile dev + academic research. Speaks Indonesian; replies in English.
- Toolchain: Claude Code (you), opencode with deepseek/gemini workers, RTK, Flutter. His global working style + delegation rules return once `~/.claude` is restored (see below) — follow them.
- This is his **main desktop**. Decision: **full wipe, no dual-boot**. Already executed.
- This repo = his Hyprland dotfiles. You should be on branch **desktop** (`git -C ~/.dotfiles ... checkout desktop` if not).

## Hardware
Ryzen 7 5700X · **RX 9060 XT (RDNA4, all-AMD)** · ASRock B550M Pro4 (BIOS P2.80) ·
32GB DDR4-3600 · displays: **MSI MAG 275QF 2K@170** (primary) + **27B1H2 1080p** ·
wired **Realtek GbE**. Two NVMes: **Lexar NM790 2TB (wiped → this Arch install)** and
**ADATA 710 477GB (NOT wiped → holds the backup)**.

## What already happened (before the wipe)
Everything irreplaceable was backed up onto the **ADATA disk, which was deliberately
left untouched.** Only the Lexar got wiped + Arch.

**The ADATA is still NTFS** (old Windows label "Other Stuff"). Mount it to reach the backup:
```bash
lsblk -f                       # find the ~477G NTFS partition (not the root btrfs)
sudo mkdir -p /mnt/adata
sudo mount -t ntfs3 /dev/nvmeXn1pY /mnt/adata
ls /mnt/adata/arch-backup
```
Backup contents at `/mnt/adata/arch-backup/`:
- `backup-20260629-110753/`
  - `KEYSTORE/` — **19 Android `.jks` signing keys + a GCP service-account json** (irreplaceable)
  - `KEYSTORE-sha256.txt` — verify the keystores against this after restoring
  - `env-files/automation_.env` — AppSheet bot credentials
  - `.claude/`, `opencode/`, `.ssh/`, `.gitconfig`, `Bookmarks`
- `backup-20260629-110753/CODE-full/` — **all 30 repos with full `.git`** (includes
  uncommitted + stashed + unpushed work that the GitHub remotes DON'T have)
- `KEYSTORE-cloud.zip` — same keys, also uploaded to the user's Google Drive
- `archlinux-x86_64.iso` — the installer that was used (ignore)

## Restoring code (important nuance)
Prefer restoring `~/CODE` **from `CODE-full`**, not re-cloning — it preserves the
stashes and uncommitted/unpushed work. `node_modules`, `build`, `.dart_tool` were
excluded, so regenerate them (`flutter pub get`, `npm i`).
```bash
mkdir -p ~/CODE && cp -a /mnt/adata/arch-backup/backup-20260629-110753/CODE-full/. ~/CODE/
```
Re-clone (the list in `ARCH-SETUP.md` Phase 9) only if the user wants clean-from-remote instead.

Restore the rest:
```bash
cp -a /mnt/adata/arch-backup/backup-20260629-110753/.claude   ~/.claude
cp -a /mnt/adata/arch-backup/backup-20260629-110753/opencode  ~/.config/opencode
cp -a /mnt/adata/arch-backup/backup-20260629-110753/.ssh      ~/.ssh && chmod 700 ~/.ssh
cp /mnt/adata/arch-backup/backup-20260629-110753/.gitconfig   ~/.gitconfig
mkdir -p ~/CODE/automation && cp /mnt/adata/arch-backup/backup-20260629-110753/env-files/automation_.env ~/CODE/automation/.env
```

## Gotchas / must-not-miss
- **KEYSTORE is the one unrecoverable thing.** Restore to `~/CODE/KEYSTORE`, verify SHA256, never leak.
- 🔒 **Rotate the GitHub token** that was embedded in the old `sidigs` remote URL (it's in that repo's `.git/config` inside CODE-full).
- **RDNA4 is new** — confirm `vulkaninfo | grep -i radeon` shows the card; if empty, the kernel/firmware is too old, update + reboot.
- `~/.config/hypr/monitors.conf` has *guessed* connector names (DP-1 / HDMI-A-1) — fix from `hyprctl monitors all` on first boot.
- The 3 systemd user timers (`appsheet-daily`, `appsheet-presensi`, `claude-ping`) port his old Windows Task Scheduler jobs. The automation needs its `.env` + `npx playwright install chromium`. Enable with `loginctl enable-linger` first.
- Non-game anchors (no native Linux): MS Office → LibreOffice/web, Illustrator → Inkscape, SPSS → jamovi. Games are all fine on Proton (verified).

## Your job
Read `ARCH-SETUP.md` and execute it. Pause only at the 🟡 ME steps (logins, mounting/
decrypting the backup, monitor confirmation, anchor-app choices). At the end, report
what passed, what still needs the user, and anything broken.
