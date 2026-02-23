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

    # Dev
    git
    base-devel

    # File manager
    dolphin

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
