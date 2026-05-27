# Suji's Arch / Hyprland setup

Notes for re-creating this setup on a fresh Arch install.

## Files in this folder

- `packages-pacman.txt` — explicit packages from official repos (`pacman -Qqen`)
- `packages-aur.txt` — explicit packages from AUR / foreign (`pacman -Qqem`)

These are auto-generated snapshots. Regenerate before committing:

```bash
pacman -Qqen > ~/.config/setup/packages-pacman.txt
pacman -Qqem > ~/.config/setup/packages-aur.txt
```

## Fresh-install order

1. Install Arch with `archinstall` or manual: base, base-devel, linux, linux-firmware, networkmanager, sudo, vim, git.
2. Boot, log in as user. Set up dotfiles bare repo:

   ```bash
   git clone --bare https://github.com/Soejii/dotfiles $HOME/.dotfiles
   alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
   dotfiles checkout
   dotfiles config status.showUntrackedFiles no
   ```

3. Install official-repo packages:

   ```bash
   sudo pacman -S --needed - < ~/.config/setup/packages-pacman.txt
   ```

4. Bootstrap `yay`, then AUR packages:

   ```bash
   # yay must be in packages-aur.txt
   git clone https://aur.archlinux.org/yay.git /tmp/yay
   cd /tmp/yay && makepkg -si
   yay -S --needed - < ~/.config/setup/packages-aur.txt
   ```

5. Enable services:

   ```bash
   sudo systemctl enable --now NetworkManager bluetooth ufw power-profiles-daemon
   sudo ufw default deny incoming && sudo ufw default allow outgoing && sudo ufw --force enable
   ```

6. Build the Catppuccin GTK theme (not in dotfiles, must be regenerated):

   ```bash
   git clone --depth=1 https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme /tmp/cat-gtk
   /tmp/cat-gtk/themes/install.sh -n Catppuccin -t blue -c dark -s standard -l
   ```

7. Set wallpaper at `~/Pictures/Wallpapers/dark-cat.png` (referenced by hyprpaper).

8. `mkdir -p ~/Pictures/Screenshots` (referenced by grimblast bind).

9. Reboot.

## Key configs covered by dotfiles

- Hyprland: `~/.config/hypr/{hyprland,hypridle,hyprlock,hyprpaper,hyprsunset}.conf`
- Bar / launcher / notifications: `~/.config/{waybar,wofi,dunst}/`
- Terminal: `~/.config/alacritty/alacritty.toml`
- Prompt: `~/.config/starship.toml`
- GTK: `~/.config/gtk-3.0/settings.ini`, `~/.config/gtk-4.0/settings.ini`
- File associations: `~/.config/mimeapps.list`
- Custom binaries: `~/.local/bin/{hypr-compact-workspaces,hyprsunset-toggle,hypr-cheatsheet,start-hyprpaper,power-profile-monitor.sh}`
- Launcher entry hides: `~/.local/share/applications/thunar-*.desktop`
- Shell: `~/.bashrc`
