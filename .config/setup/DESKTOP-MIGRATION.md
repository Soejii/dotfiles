# Desktop → Arch migration (full wipe, no dual-boot)

Machine: Ryzen 7 5700X · RX 9060 XT (RDNA4) · ASRock B550M Pro4 · 32GB DDR4-3600 ·
Lexar NM790 2TB + ADATA 710 477GB · dual 1440p (MSI MAG 275QF + 27B1H2) · wired Realtek GbE.

Work top-to-bottom. Phase 0 is the only irreversible-if-skipped part.

---

## Phase 0 — Back up the irreplaceable (DO FIRST)
- [ ] Run `00-backup-prewipe.ps1` (dry run) and read the report.
- [ ] Plug in an external/USB drive, then `.\00-backup-prewipe.ps1 -Execute -Dest E:\arch-backup`.
- [ ] **KEYSTORE** (~20 .jks + GCP json) saved + SHA256 manifest verified. Encrypt the bundle (`7z a -p -mhe=on keys.7z ...`). This is the one thing you can never regenerate.
- [ ] Push every dirty/unpushed repo the report lists (flutter_clean_architecture, nakula, sadewa, arjuna, sidigs, StriveFrameViewer, gaia, icarus).
- [ ] no-git folders saved: automation (+.env+assets), absen, ggst-input-tracker, ggst-pocket-finder, nakula-cli, sadewa-cli, BUILDS.
- [ ] Chrome: turn on **Sync** (passwords are DPAPI-bound, won't decrypt on Linux) + export bookmarks.
- [ ] Grab 2FA/authenticator seeds + password vault export.
- [ ] Note non-Steam / cracked game saves; export Hyper-V `cowork-vm-nat` disk if you still need that VM (→ KVM later).
- [ ] Confirm laptop dotfiles repo is pushed (it's the base for the desktop).

## Phase 1 — Install Arch
- [ ] BIOS: enable **Resizable BAR** + **Above 4G Decoding**, **EXPO/DOCP** (DDR4-3600).
- [ ] `archinstall`: filesystem **btrfs** (default subvols), bootloader **GRUB**, primary kernel **linux** (RDNA4 needs current Mesa/firmware), add **linux-lts** as fallback.
- [ ] First boot, then follow `.config/setup/btrfs-snapper.md` for the snapper/grub-btrfs parachute.
- [ ] Enable `[multilib]` in `/etc/pacman.conf`, `sudo pacman -Syu`.

## Phase 2 — Dotfiles + desktop overlay
- [ ] Bare-repo checkout per the repo README.
- [ ] Add the overlay files (this kit's `dotfiles-overlay/`): `hypr/monitors.conf`, the 3 systemd timers, `.local/bin/claude-ping.sh`, the setup package lists.
- [ ] In `hypr/hyprland.conf`: replace the `eDP-1` line with `source = ~/.config/hypr/monitors.conf`; after boot run `hyprctl monitors all` and fix connector names/refresh in monitors.conf.
- [ ] In `waybar/config`: change `"interface": "wlan0"` → your wired iface (`ip link`, e.g. `enp34s0`) or remove the line.
- [ ] `chmod +x ~/.local/bin/claude-ping.sh`.

## Phase 3 — Packages
- [ ] Install base from `packages-pacman.txt` MINUS everything in `packages-strip.txt` (Intel/laptop cruft).
- [ ] Install `packages-desktop-add.txt` (AMD lib32, mangohud, lutris/wine, snapper, inkscape, openrgb).
- [ ] `yay` + `packages-aur.txt` + the AUR extras (lact, davinci-resolve, protonup-qt, sober).
- [ ] Verify GPU: `vulkaninfo | grep -i radeon`, `glxinfo | grep RX`, run `mangohud glxgears`.

## Phase 4 — Toolchain
- [ ] node/npm, python (3.10 + 3.13), git, `gh auth login`, dart/Flutter, JDK17 + Android Studio + android-tools (adb), opencode + RTK + Claude Code (`npm i -g @anthropic-ai/claude-code`).
- [ ] Restore `~/.claude`, `~/.config/opencode`, keystores into `~/CODE/KEYSTORE`.
- [ ] Re-clone your 30 `C:\CODE` repos under `~/CODE`.

## Phase 5 — Automation → systemd user timers
- [ ] `cd ~/CODE/automation && npm install && npx playwright install chromium` (+ deps: nss, alsa-lib, libxkbcommon, at-spi2-core, cups, libdrm — Playwright will list missing libs).
- [ ] Recreate `automation/.env` (APPSHEET_USERNAME/PASSWORD) from the backup; restore `assets/`.
- [ ] `loginctl enable-linger $USER` (timers run without an active login).
- [ ] `systemctl --user daemon-reload`
- [ ] `systemctl --user enable --now appsheet-daily.timer appsheet-presensi.timer claude-ping.timer`
- [ ] Verify: `systemctl --user list-timers`; test once: `systemctl --user start appsheet-presensi.service` and check `presensi_log.txt`.

## Phase 6 — Apps & games
- [ ] Native: DaVinci Resolve, OBS, GIMP, Obsidian, VLC, Postman, VS Code, Discord (vesktop), Telegram, Zoom, Pandoc/Tesseract/wkhtmltox.
- [ ] Academic: jamovi (SPSS replacement, or SPSS Linux build if you have the license), Mendeley, Publish-or-Perish (Wine if no native), LibreOffice.
- [ ] Steam: enable Proton (Settings → Compatibility → Steam Play for all titles), set **GE-Proton** via protonup-qt. Library is Proton-clean (ARC Raiders platinum, BattleBit gold, GGST/Elden Ring verified, Dota2/CS2/Deadlock native).
- [ ] Non-Steam / cracked → Lutris/Bottles + Wine. Japanese-engine VNs: `noto-fonts-cjk` (already installed) + launch with `LANG=ja_JP.UTF-8` to avoid mojibake.
- [ ] Roblox → `sober` (Flatpak). GPU OC/fans → LACT. RGB → OpenRGB.

---

### Replacement cheat-sheet
| Windows | Arch |
|---|---|
| MSI Afterburner + RivaTuner | LACT (fans/clocks) + MangoHud (overlay) |
| HWiNFO / GPU-Z | btop, lm_sensors, nvtop/amdgpu_top |
| Macrium Reflect | snapper + btrfs snapshots |
| ASRRGBLED (Polychrome) | OpenRGB |
| Hamachi | haguichi+logmein-hamachi (AUR) or ZeroTier/Tailscale |
| Cloudflare WARP | cloudflare-warp-bin (AUR), `warp-cli` |
| Adobe Illustrator | Inkscape |
| MS Office | LibreOffice / Office web |
| IBM SPSS | jamovi (or SPSS for Linux) |
| Hyper-V VMs | KVM/QEMU/libvirt/virt-manager (in your pkg list) |
| Cheat Engine | scanmem / GameConqueror |
