#!/usr/bin/env bash
set -euo pipefail

DISK="/dev/mmcblk1"
VERSION="4.0.4"
ISO="omarchy-${VERSION}.iso"
URL="https://iso.omarchy.org/${ISO}"
SHA256="ddeded2758c48318d201dfdac905ecb28f570441883f0c052ea3cd5d05acf92d"

die() { echo "ERROR: $*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "Run as root."
[ "$(uname -m)" = "x86_64" ] || die "Expected x86_64."
[ -d /sys/firmware/efi ] || die "Grml must be booted in UEFI mode."
[ -b "$DISK" ] || die "$DISK does not exist."

echo "TARGET: $DISK"
lsblk "$DISK"
echo
echo "This script will ERASE $DISK, install a temporary Omarchy boot environment,"
echo "set it as the next UEFI boot target, and reboot automatically."
echo
sleep 5

export DEBIAN_FRONTEND=noninteractive

echo "[1/8] Installing tools..."
apt-get update
apt-get install -y \
  curl ca-certificates parted dosfstools e2fsprogs \
  grub-efi-amd64-bin grub-common efibootmgr lvm2

echo "[2/8] Releasing old Ubuntu mounts/LVM..."

swapoff -a || true

mapfile -t DEVS < <(lsblk -lnpo NAME "$DISK" | tac)
for dev in "${DEVS[@]}"; do
  while true; do
    target="$(findmnt -rn -S "$dev" -o TARGET 2>/dev/null | head -n1 || true)"
    [ -n "$target" ] || break
    umount "$target" 2>/dev/null || umount -l "$target" 2>/dev/null || true
  done
done

lvchange -an vgubuntu/root 2>/dev/null || true
lvchange -an vgubuntu/swap_1 2>/dev/null || true
vgchange -an vgubuntu 2>/dev/null || true

udevadm settle

if lsblk -lnpo NAME,TYPE "$DISK" | awk '$2=="lvm"{found=1} END{exit !found}'; then
  echo "Active LVM devices still exist:"
  lsblk "$DISK"
  die "Could not release old vgubuntu devices."
fi

echo "[3/8] Repartitioning $DISK..."
wipefs -af "$DISK"
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart OMARCHY_EFI fat32 1MiB 513MiB
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart OMARCHY_ISO ext4 513MiB 8705MiB

blockdev --rereadpt "$DISK" || true
partprobe "$DISK"
udevadm settle

ESP="/dev/mmcblk1p1"
STORE="/dev/mmcblk1p2"

[ -b "$ESP" ] || die "Missing $ESP after repartition."
[ -b "$STORE" ] || die "Missing $STORE after repartition."

echo "[4/8] Formatting temporary boot partitions..."
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

echo "[5/8] Downloading Omarchy $VERSION..."
curl -fL --retry 8 --retry-delay 2 -C - \
  -o "/mnt/omarchy-store/$ISO" \
  "$URL"

echo "[6/8] Verifying SHA256..."
echo "$SHA256  /mnt/omarchy-store/$ISO" | sha256sum -c -

mount -o loop,ro "/mnt/omarchy-store/$ISO" /mnt/omarchy-iso
[ -f /mnt/omarchy-iso/boot/grub/loopback.cfg ] ||
  die "ISO is missing /boot/grub/loopback.cfg"
umount /mnt/omarchy-iso

STORE_UUID="$(blkid -s UUID -o value "$STORE")"
[ -n "$STORE_UUID" ] || die "Could not read ISO partition UUID."

echo "[7/8] Building UEFI Omarchy launcher..."

cat >/tmp/omarchy-grub.cfg <<GRUB
set timeout=1
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

mkdir -p /mnt/omarchy-esp/EFI/BOOT

grub-mkstandalone \
  -O x86_64-efi \
  -o /mnt/omarchy-esp/EFI/BOOT/BOOTX64.EFI \
  "boot/grub/grub.cfg=/tmp/omarchy-grub.cfg"

sync

echo "[8/8] Setting Omarchy as next UEFI boot..."

while read -r bootnum; do
  [ -n "$bootnum" ] && efibootmgr -b "$bootnum" -B 2>/dev/null || true
done < <(
  efibootmgr 2>/dev/null |
  sed -n 's/^Boot\([0-9A-Fa-f]\{4\}\)\*\?[[:space:]]\+Omarchy Installer.*$/\1/p'
)

efibootmgr \
  --create \
  --disk "$DISK" \
  --part 1 \
  --label "Omarchy Installer" \
  --loader '\EFI\BOOT\BOOTX64.EFI'

BOOTNUM="$(
  efibootmgr |
  sed -n 's/^Boot\([0-9A-Fa-f]\{4\}\)\*\?[[:space:]]\+Omarchy Installer.*$/\1/p' |
  head -n1
)"

[ -n "$BOOTNUM" ] || die "Could not determine new UEFI boot entry."
efibootmgr --bootnext "$BOOTNUM"

sync
cleanup
trap - EXIT

echo
echo "Prepared successfully."
echo "Rebooting directly into Omarchy installer..."
echo
echo "IMPORTANT: When Omarchy asks where to install, choose FREE SPACE."
echo "Do not choose full-disk install while the ISO is stored on partition 2."
echo

sleep 3
reboot
