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
