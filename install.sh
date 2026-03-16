#!/bin/bash

set -e

echo "==> Starting Soejii's Arch setup..."

# ── Packages ─────────────────────────────────────────────────────────────────

PACKAGES=(
    # Hyprland ecosystem
    hyprland
    hypridle
    hyprlock
    xdg-desktop-portal-hyprland

    # Wayland essentials
    waybar
    wofi
    dunst
    alacritty
    grim
    slurp
    wl-clipboard
    cliphist

    # Network & bluetooth
    networkmanager
    network-manager-applet
    bluez
    bluez-utils
    blueman

    # Audio
    pipewire
    pipewire-alsa
    pipewire-pulse
    pipewire-jack
    wireplumber

    # Auth
    polkit-gnome

    # Media & brightness
    brightnessctl
    playerctl
    pavucontrol

    # Fonts
    ttf-jetbrains-mono-nerd
    noto-fonts
    noto-fonts-emoji

    # Icons
    breeze-icons

    # Shell tools
    zoxide
    fzf
    ccache
    btop
    starship

    # Gaming
    gamemode
    lib32-gamemode

    # Dev
    git
    base-devel
    nodejs
    npm

    # File manager
    dolphin

    # Fonts & icons
    ttf-nerd-fonts-symbols

    # Screenshot deps
    slurp
)

echo "==> Installing packages..."
sudo pacman -Syu --needed --noconfirm "${PACKAGES[@]}"

# ── Dotfiles ──────────────────────────────────────────────────────────────────

echo "==> Cloning dotfiles..."
git clone --bare https://github.com/Soejii/dotfiles.git "$HOME/.dotfiles"

function dotfiles {
    /usr/bin/git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" "$@"
}

dotfiles config --local status.showUntrackedFiles no

echo "==> Checking out dotfiles..."
dotfiles checkout 2>/dev/null || {
    echo "==> Backing up conflicting files..."
    mkdir -p ~/.dotfiles-backup
    dotfiles checkout 2>&1 | grep "^\s" | awk '{print $1}' | xargs -I{} sh -c 'mkdir -p ~/.dotfiles-backup/$(dirname {}) && mv ~/{} ~/.dotfiles-backup/{}'
    dotfiles checkout
}

# ── CLI tools (curl installs) ─────────────────────────────────────────────────

echo "==> Installing cship (Claude Code statusline)..."
curl -fsSL https://cship.dev/install.sh | bash

echo "==> Setting up npm global prefix..."
mkdir -p "$HOME/.npm-global"
npm config set prefix "$HOME/.npm-global"

echo "==> Installing gemini CLI..."
"$HOME/.npm-global/bin/npm" install -g @google/gemini-cli

# ── Services ──────────────────────────────────────────────────────────────────

echo "==> Enabling services..."
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth

systemctl --user enable pipewire pipewire-pulse wireplumber

# ── Power profile monitor ─────────────────────────────────────────────────────

echo "==> Enabling power profile monitor..."
systemctl --user enable power-profile-monitor.service

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo "==> Done! Reboot and start Hyprland."
echo "==> Note: check hyprland.conf monitor name and waybar network interface for this machine."
