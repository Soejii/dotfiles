# btrfs rollback parachute (your no-dual-boot safety net)

Goal: a bad `pacman -Syu` is a 30-second rollback from the GRUB menu, not a reinstall.

## At install time (archinstall)
- Filesystem: **btrfs**, accept the default subvolume layout (`@`, `@home`, `@log`, `@pkg`, `@snapshots`).
- Bootloader: **GRUB** (grub-btrfs needs GRUB; systemd-boot won't show snapshot entries).

## After first boot
```bash
sudo pacman -S snapper snap-pac grub-btrfs inotify-tools

# root config (snapper expects /.snapshots to be the @snapshots subvol)
sudo umount /.snapshots 2>/dev/null
sudo rm -rf /.snapshots
sudo snapper -c root create-config /
sudo btrfs subvolume delete /.snapshots
sudo mkdir /.snapshots
sudo mount -a
sudo chmod 750 /.snapshots

# keep snapshots sane
sudo sed -i 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="5"/;
             s/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="7"/;
             s/^TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="2"/;
             s/^TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="0"/;
             s/^TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' /etc/snapper/configs/root

sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
sudo systemctl enable --now grub-btrfs.path        # auto-regen GRUB menu on new snapshot
```

`snap-pac` then auto-snapshots before/after every `pacman` transaction. To roll back:
boot GRUB > "Arch snapshots" submenu > pick the pre-update snapshot, then make it
permanent with `snapper rollback` from the booted snapshot.

## Worth doing alongside
- `sudo pacman -S zram-generator` (already in your list) for swap-on-RAM.
- Keep `linux` (mainline) as primary kernel for RDNA4; `linux-lts` as a fallback entry.
