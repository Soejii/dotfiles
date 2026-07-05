# dotfiles

My personal Arch Linux + Hyprland setup.

## Setup

| Component | Tool |
|---|---|
| WM | Hyprland |
| Bar | Waybar |
| Terminal | Alacritty |
| Launcher | Wofi |
| Notifications | Dunst |
| Idle | Hypridle |
| Lock | Hyprlock |
| Shell | Bash + zoxide + fzf |
| Clipboard | cliphist |
| Audio | PipeWire |

## Install

On a fresh Arch install:

```bash
curl -s https://raw.githubusercontent.com/Soejii/dotfiles/master/install.sh | bash
```

Then reboot and start Hyprland.

## Notes

Some configs are machine-specific and may need tweaking after install:

- `~/.config/hypr/hyprland.conf` — monitor name (currently `eDP-1`)
- `~/.config/waybar/config` — network interface (currently `wlan0`)

## Claude window pinger

A systemd user timer that sends a minimal Haiku ping through the Claude Code
subscription at 09:00 / 14:00 / 19:00 to anchor the rolling 5-hour usage window.

Files (tracked here):

- `~/.local/bin/claude-ping.sh` — the ping script, logs to `~/.claude/window-pinger/ping.log`
- `~/.config/systemd/user/claude-ping.service` + `claude-ping.timer`

Enable with:

```bash
systemctl --user enable --now claude-ping.timer
```

**Auth (required, not tracked):** headless `claude -p` cannot refresh an expired
OAuth access token (8h TTL), so any run more than 8h after the last interactive
session fails with a 401
([claude-code#53063](https://github.com/anthropics/claude-code/issues/53063)).
The script therefore reads a long-lived subscription token from
`~/.claude/window-pinger/oauth-token`. On a fresh machine (or when the token
expires, roughly yearly — current one is from Jul 2026):

```bash
claude setup-token   # browser login, prints an sk-ant-oat... token
(umask 077; cat > ~/.claude/window-pinger/oauth-token)   # paste, Enter, Ctrl-D
```

Do **not** set `ANTHROPIC_API_KEY` for the pinger; that bills the API per-token
instead of touching the subscription window. Health check: `tail ~/.claude/window-pinger/ping.log`
or `systemctl --user --failed` (the script exits non-zero on a failed ping).
