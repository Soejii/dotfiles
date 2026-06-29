# Arch desktop setup runbook

> **For Claude Code.** You are running on a freshly installed Arch Linux on my main
> desktop. Execute this file top to bottom. Run every non-interactive command
> yourself. Stop and ask me ONLY at steps marked **🟡 ME** (logins, secrets,
> physical actions, irreversible choices). After each phase, run its **✅ gate**
> and do not continue until it passes. If a gate fails, fix it (or feed the error
> back) before moving on. Prefer `--needed --noconfirm` so you don't block.

## This machine
- CPU **AMD Ryzen 7 5700X** (amd-ucode) · GPU **AMD RX 9060 XT (RDNA4)** · Board **ASRock B550M Pro4**
- 32 GB DDR4-3600 · NVMe: Lexar NM790 2TB (root) + ADATA 710 477GB
- Displays: **MSI MAG 275QF 2K@170** (primary) + **27B1H2 1080p** · Wired **Realtek GbE**
- User: `sujia`. Code lives in `~/CODE`. Dotfiles are a bare repo on branch **desktop**.

---

## Phase 0 — BEFORE the wipe (on Windows, do this yourself) 🟡 ME
The pre-wipe backup script is committed at `.config/setup/00-backup-prewipe.ps1`.
On the old Windows install, with an external drive plugged in:
```powershell
.\00-backup-prewipe.ps1                     # dry run, review
.\00-backup-prewipe.ps1 -Execute -Dest E:\arch-backup
```
This saves the irreplaceable stuff: `KEYSTORE` (~20 .jks signing keys + GCP json),
the no-git folders (`automation`,`absen`,`ggst-*`,`nakula-cli`,`sadewa-cli`,`BUILDS`),
every `.env`, and `~/.claude`/`~/.config/opencode`/`~/.ssh`. Push the dirty/unpushed
repos it lists. Enable Chrome Sync (passwords are DPAPI-bound). **Encrypt the bundle.**
Then install Arch and run me with this file.

**Assumed already done before I run:** Arch base installed (btrfs, GRUB, `linux`+`linux-lts`),
networked, user `sujia` with sudo, dotfiles bare repo checked out on branch `desktop`,
and the backup drive reachable.

---

## Phase 1 — System base + multilib
```bash
sudo sed -i '/^#\[multilib\]/,+1 s/^#//' /etc/pacman.conf   # uncomment [multilib]
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm git base-devel reflector
```
**✅ gate:** `pacman -Sl multilib >/dev/null && echo multilib-ok`

## Phase 2 — Packages (repo)
Install the laptop base MINUS the laptop/Intel cruft, then the desktop additions.
```bash
cd ~/.config/setup
# base snapshot minus everything listed in packages-strip.txt
comm -23 <(sort -u packages-pacman.txt) \
        <(grep -vE '^\s*#|^\s*$' packages-strip.txt | sort -u) \
  | sudo pacman -S --needed --noconfirm -
# desktop additions (AMD lib32, mangohud, lutris/wine, snapper, inkscape, openrgb)
grep -vE '^\s*#|^\s*$' packages-desktop-add.txt | sudo pacman -S --needed --noconfirm -
```
**✅ gate:** `pacman -Q steam vulkan-radeon lib32-vulkan-radeon mangohud lutris snapper >/dev/null && echo pkgs-ok`

## Phase 3 — AUR (yay + foreign packages)
```bash
if ! command -v yay >/dev/null; then
  git clone https://aur.archlinux.org/yay.git /tmp/yay && (cd /tmp/yay && makepkg -si --noconfirm)
fi
yay -S --needed --noconfirm - < <(grep -vE '^\s*#|^\s*$' ~/.config/setup/packages-aur.txt)
# migration extras
yay -S --needed --noconfirm lact davinci-resolve protonup-qt sober cloudflare-warp-bin
```
**✅ gate:** `command -v yay && pacman -Q lact >/dev/null && echo aur-ok`

## Phase 4 — GPU verify (RDNA4 is new — confirm it's alive)
```bash
pacman -Q linux linux-firmware mesa vulkan-radeon
vulkaninfo 2>/dev/null | grep -i "deviceName.*Radeon" || echo "NO RADEON VULKAN DEVICE"
```
**✅ gate:** vulkaninfo shows the RX 9060 XT. If empty, kernel/firmware may be too old —
update and reboot before continuing. (RDNA4 needs current `linux` + `linux-firmware`.)

## Phase 5 — btrfs rollback parachute
```bash
sudo umount /.snapshots 2>/dev/null; sudo rm -rf /.snapshots
sudo snapper -c root create-config /
sudo btrfs subvolume delete /.snapshots 2>/dev/null
sudo mkdir /.snapshots && sudo mount -a && sudo chmod 750 /.snapshots
sudo sed -i 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="5"/;
             s/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="7"/;
             s/^TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="2"/;
             s/^TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="0"/;
             s/^TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' /etc/snapper/configs/root
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer grub-btrfs.path
```
**✅ gate:** `sudo snapper -c root list >/dev/null && systemctl is-active grub-btrfs.path`

## Phase 6 — Services + firewall
```bash
sudo systemctl enable --now NetworkManager bluetooth
sudo systemctl enable lightdm
systemctl --user enable --now pipewire pipewire-pulse wireplumber
sudo ufw default deny incoming && sudo ufw default allow outgoing && sudo ufw --force enable && sudo systemctl enable --now ufw
```
**✅ gate:** `systemctl is-enabled NetworkManager lightdm ufw`

## Phase 7 — Hyprland / monitors / theme
The dotfiles already ship hypr + waybar configs; `hyprland.conf` sources
`monitors.conf` (2K@170 primary + 1080p). After you can start a Hyprland session:
```bash
hyprctl monitors all     # read the REAL connector names + modes
```
🟡 **ME:** confirm the connector names/refresh, then fix `~/.config/hypr/monitors.conf`
if `DP-1`/`HDMI-A-1` or the refresh don't match. Also build the GTK theme:
```bash
git clone --depth=1 https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme /tmp/cat-gtk
/tmp/cat-gtk/themes/install.sh -n Catppuccin -t blue -c dark -s standard -l
mkdir -p ~/Pictures/Wallpapers ~/Pictures/Screenshots
```
(`~/.local/bin/start-hyprpaper` + hyprpaper.conf expect a wallpaper there.)

## Phase 8 — Dev toolchain
Most tools are already installed via the package lists (nodejs, npm, python, dart,
jdk-openjdk, jdk17-openjdk, android-tools, android-studio, github-cli, flutter via AUR if listed).
```bash
npm config set prefix "$HOME/.npm-global"
"$HOME/.npm-global/bin/npm" install -g @anthropic-ai/claude-code @google/gemini-cli || npm install -g @anthropic-ai/claude-code @google/gemini-cli
curl -fsSL https://cship.dev/install.sh | bash      # cship statusline
```
🟡 **ME:** authenticate accounts — `gh auth login`, `claude` (claude.ai login),
`opencode auth login`, install RTK. (These need my credentials; do not guess.)
**✅ gate:** `node -v && python --version && java -version && flutter --version && gh auth status`

## Phase 9 — Restore code + secrets 🟡 ME
Mount the backup drive and decrypt the bundle, then:
```bash
mkdir -p ~/CODE
# keystores (CRITICAL — verify checksums against KEYSTORE-sha256.txt)
cp -r /run/media/$USER/<backup>/KEYSTORE ~/CODE/KEYSTORE
# automation creds + assets
mkdir -p ~/CODE/automation
cp /run/media/$USER/<backup>/env-files/automation_.env ~/CODE/automation/.env
```
Re-clone the repos (gh auth from Phase 8 must be done first):
```bash
cd ~/CODE
clone(){ git clone "$2" "$1" 2>/dev/null && git -C "$1" checkout "$3" 2>/dev/null; }
# --- my repos (github: Soejii) ---
clone Anthesis      https://github.com/Soejii/anthesis.git           master
clone anusapati     https://github.com/Soejii/anusapati.git          dev
clone behavior_bridge https://github.com/Soejii/behavior_bridge.git  master
clone chiron        https://github.com/Soejii/chiron.git             feat/nilai
clone freesia       https://github.com/Soejii/freesia.git            redesign/dino-meter
clone gaia          https://github.com/Soejii/gaia.git               feature-e-pkl
clone google-form-tester https://github.com/Soejii/google-form-tester.git master
clone icarus        https://github.com/Soejii/icarus.git             master
clone lavender      https://github.com/Soejii/lavender.git           master
clone memberku      https://github.com/Soejii/memberku.git           main
clone pulse_flow    https://github.com/Soejii/pulse_flow.git         main
# --- work repos (github: sidigs-id) ---
clone arjuna        https://github.com/sidigs-id/arjuna.git          GetxState
clone karna         https://github.com/sidigs-id/karna.git           main
clone nakula        https://github.com/sidigs-id/nakula.git          main
clone sadewa        https://github.com/sidigs-id/sadewa.git          dev-suji
clone sidigs        https://github.com/sidigs-id/sidigs.git          master
clone marbot-app    https://gitlab.com/Muhammadaan/marbot-app.git    dev-dika
# --- external / forks (optional) ---
clone flutter_clean_architecture https://github.com/heygourab/flutter_clean_architecture.git main
clone puddle-farm   https://github.com/nemasu/puddle-farm.git        master
clone StriveFrameViewer https://github.com/Sevoii/StriveFrameViewer.git master
clone subtask       https://github.com/zippoxer/subtask.git          main
```
Restore from backup (no git, can't clone): `absen`, `ggst-input-tracker`,
`ggst-pocket-finder`, `nakula-cli`, `sadewa-cli`, `BUILDS`.
**🔒** rotate the GitHub token that was embedded in the old `sidigs` remote URL.

## Phase 10 — Automation timers (the ported Task Scheduler jobs)
```bash
cd ~/CODE/automation && npm install && npx playwright install chromium
# playwright will print any missing system libs; install them with pacman if so
loginctl enable-linger "$USER"
systemctl --user daemon-reload
systemctl --user enable --now appsheet-daily.timer appsheet-presensi.timer claude-ping.timer
```
**✅ gate:** `systemctl --user list-timers | grep -E 'appsheet|claude-ping'` shows all three.
Smoke test: `systemctl --user start appsheet-presensi.service; sleep 5; tail ~/CODE/automation/presensi_log.txt`

## Phase 11 — Apps & games
```bash
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```
- Steam → Settings ▸ Compatibility ▸ enable **Steam Play for all titles**; use
  **protonup-qt** to install latest **GE-Proton**. Library is Proton-clean
  (ARC Raiders platinum, BattleBit gold, GGST/Elden Ring verified, Dota2/CS2/Deadlock native).
- Non-Steam / cracked → **Lutris/Bottles + Wine**. Japanese VNs: `noto-fonts-cjk`
  (already installed) + launch with `LANG=ja_JP.UTF-8` to avoid mojibake.
- Roblox → `sober` (installed in Phase 3). RGB → `openrgb`. GPU fans/OC → `lact`.

🟡 **ME — anchor replacements (decide, no native equivalents):**
| Windows app | Linux plan |
|---|---|
| MS Office | LibreOffice (in base) / Office web |
| Adobe Illustrator | Inkscape (in desktop-add) |
| IBM SPSS | jamovi, or SPSS Linux build if I have the license |
| DaVinci Resolve | native (AUR), uses ROCm/HIP |

## Phase 12 — Final verification
```bash
systemctl --user list-timers
flutter doctor
vulkaninfo | grep -i radeon
sudo snapper -c root list
```
Report what passed, what needs my input, and anything still broken. **Done.**
