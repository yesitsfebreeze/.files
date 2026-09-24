#!/usr/bin/env bash
set -euo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "Run as root."
[ "$(uname -m)" = "x86_64" ] || die "This installer currently supports x86_64 only."
[ -d /sys/firmware/efi ] || die "Grml must be booted in UEFI mode."

echo "Finding latest Omarchy release..."
VERSION=$(curl -fsSL https://api.github.com/repos/omacom/omarchy/releases/latest |
  sed -n 's/.*"tag_name":[[:space:]]*"v\([^"]*\)".*/\1/p' |
  head -n1)

[ -n "$VERSION" ] || die "Could not determine latest Omarchy version."

ISO="omarchy-$VERSION.iso"
URL="https://iso.omarchy.org/$ISO"

echo
echo "Omarchy: $VERSION"
echo "Source:  $URL"
echo
echo "Available disks:"
lsblk -dpno NAME,SIZE,MODEL,TYPE | awk '$4=="disk"'
echo
read -r -p "Target disk to ERASE (example /dev/nvme0n1): " DISK </dev/tty

[ -b "$DISK" ] || die "Not a block device: $DISK"
[ "$(lsblk -dnro TYPE "$DISK")" = "disk" ] || die "Target must be a whole disk."

echo
echo "THIS ERASES THE ENTIRE DISK:"
lsblk "$DISK"
echo
read -r -p "Type ERASE to continue: " CONFIRM </dev/tty
[ "$CONFIRM" = "ERASE" ] || die "Cancelled."

export DEBIAN_FRONTEND=noninteractive

echo "Installing required Grml packages..."
apt-get update
apt-get install -y curl ca-certificates parted dosfstools e2fsprogs grub-efi-amd64-bin grub-common

echo "Unmounting target..."
swapoff -a || true
while read -r DEV; do
  [ -n "$DEV" ] && umount "$DEV" 2>/dev/null || true
done < <(lsblk -lnpo NAME,MOUNTPOINT "$DISK" | awk '$2!="" {print $1}' | sort -r)

echo "Creating temporary boot + ISO partitions..."
wipefs -af "$DISK"
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart OMARCHY_EFI fat32 1MiB 513MiB
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart OMARCHY_ISO ext4 513MiB 8705MiB
partprobe "$DISK"
udevadm settle

ESP=$(lsblk -lnpo NAME,TYPE "$DISK" | awk '$2=="part"{print $1}' | sed -n '1p')
STORE=$(lsblk -lnpo NAME,TYPE "$DISK" | awk '$2=="part"{print $1}' | sed -n '2p')

[ -b "$ESP" ] || die "Could not find EFI partition."
[ -b "$STORE" ] || die "Could not find ISO partition."

mkfs.fat -F32 -n OMARCHY_EFI "$ESP"
mkfs.ext4 -F -L OMARCHY_ISO "$STORE"

mkdir -p /mnt/omarchy-esp /mnt/omarchy-store /mnt/omarchy-iso
mount "$ESP" /mnt/omarchy-esp
mount "$STORE" /mnt/omarchy-store

cleanup() {
  umount /mnt/omarchy-iso 2>/dev/null || true
  umount /mnt/omarchy-store 2>/dev/null || true
  umount /mnt/omarchy-esp 2>/dev/null || true
}
trap cleanup EXIT

echo "Downloading Omarchy $VERSION..."
cd /mnt/omarchy-store
curl -fL --retry 5 --retry-delay 2 -C - -o "$ISO" "$URL"
curl -fL --retry 5 --retry-delay 2 -o "$ISO.sha256" "$URL.sha256"

echo "Verifying download..."
sha256sum -c "$ISO.sha256"

echo "Checking ISO boot files..."
mount -o loop,ro "/mnt/omarchy-store/$ISO" /mnt/omarchy-iso
[ -f /mnt/omarchy-iso/boot/grub/loopback.cfg ] ||
  die "Omarchy ISO does not contain /boot/grub/loopback.cfg"
umount /mnt/omarchy-iso

STORE_UUID=$(blkid -s UUID -o value "$STORE")
[ -n "$STORE_UUID" ] || die "Could not read ISO partition UUID."

cat >/tmp/omarchy-grub.cfg <<GRUB
set timeout=2
set default=0

insmod part_gpt
insmod fat
insmod ext2
insmod loopback
insmod iso9660
insmod search_fs_uuid

menuentry "Install Omarchy $VERSION" {
    search --no-floppy --fs-uuid --set=isopart $STORE_UUID
    set iso_path="/$ISO"
    loopback loop (\$isopart)\$iso_path
    set root=loop
    configfile /boot/grub/loopback.cfg
}
GRUB

echo "Creating UEFI bootloader..."
mkdir -p /mnt/omarchy-esp/EFI/BOOT
grub-mkstandalone \
  -O x86_64-efi \
  -o /mnt/omarchy-esp/EFI/BOOT/BOOTX64.EFI \
  "boot/grub/grub.cfg=/tmp/omarchy-grub.cfg"

sync
cleanup
trap - EXIT

echo
echo "READY."
echo
echo "Reboot now:"
echo "  reboot"
echo
echo "Remove the Grml USB during reboot."
echo "Boot the internal disk and choose: Install Omarchy $VERSION"
echo
echo "Inside Omarchy select the FREE SPACE install option."
echo "Do NOT choose full-disk install: the ISO is temporarily stored on this disk."
