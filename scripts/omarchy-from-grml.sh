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

ROOT_SRC="$(findmnt -nro SOURCE / 2>/dev/null || true)"
case "$ROOT_SRC" in
  "$DISK"*|/dev/mapper/vgubuntu-*) die "Refusing: current root appears to use $DISK." ;;
esac

echo "TARGET: $DISK"
lsblk "$DISK"
echo
echo "ERASING $DISK and preparing Omarchy $VERSION."
sleep 3

export DEBIAN_FRONTEND=noninteractive
cd /

echo "[1/8] Installing tools..."
apt-get update
apt-get install -y \
  curl ca-certificates parted dosfstools e2fsprogs \
  grub-efi-amd64-bin grub-common efibootmgr lvm2 psmisc

echo "[2/8] Releasing old Ubuntu disk..."

swapoff -a || true

# Kill anything still holding the old manual mount, then remove it.
if mountpoint -q /mnt/ubuntu 2>/dev/null; then
  fuser -km /mnt/ubuntu 2>/dev/null || true
  umount -R /mnt/ubuntu 2>/dev/null || umount -l /mnt/ubuntu 2>/dev/null || true
fi

# Unmount every filesystem whose source belongs to the target disk.
mapfile -t DEVS < <(lsblk -lnpo NAME "$DISK" | tac)
for dev in "${DEVS[@]}"; do
  mapfile -t TARGETS < <(findmnt -rn -S "$dev" -o TARGET 2>/dev/null | sort -r || true)
  for target in "${TARGETS[@]}"; do
    [ -n "$target" ] || continue
    fuser -km "$target" 2>/dev/null || true
    umount "$target" 2>/dev/null || umount -l "$target" 2>/dev/null || true
  done
done

# Deactivate the previous Ubuntu LVM cleanly where possible.
lvchange -an -f vgubuntu/root 2>/dev/null || true
lvchange -an -f vgubuntu/swap_1 2>/dev/null || true
vgchange -an -f vgubuntu 2>/dev/null || true
udevadm settle

# If stale device-mapper nodes remain, remove only the old Ubuntu mappings.
for map in vgubuntu-root vgubuntu-swap_1; do
  if dmsetup info "$map" >/dev/null 2>&1; then
    dmsetup remove --retry "$map" 2>/dev/null || dmsetup remove -f "$map" 2>/dev/null || true
  fi
done
udevadm settle

# There must be no kernel holders left on old target partitions.
for p in /sys/class/block/mmcblk1p*/holders/*; do
  [ -e "$p" ] || continue
  die "Target is still held by $(basename "$p"). Reboot Grml and run the script again."
done

echo "[3/8] Repartitioning $DISK..."
wipefs -af "$DISK"

# Drop any stale partition mappings before rewriting the table.
partx -d "$DISK" 2>/dev/null || true
blockdev --rereadpt "$DISK" 2>/dev/null || true

parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart OMARCHY_EFI fat32 1MiB 513MiB
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart OMARCHY_ISO ext4 513MiB 8705MiB

partprobe "$DISK"
udevadm settle

ESP="/dev/mmcblk1p1"
STORE="/dev/mmcblk1p2"

[ -b "$ESP" ] || die "Missing $ESP after repartition."
[ -b "$STORE" ] || die "Missing $STORE after repartition."

echo "[4/8] Formatting..."
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

echo "[5/8] Downloading Omarchy..."
curl -fL --retry 8 --retry-delay 2 -C - \
  -o "/mnt/omarchy-store/$ISO" \
  "$URL"

echo "[6/8] Verifying ISO..."
echo "$SHA256  /mnt/omarchy-store/$ISO" | sha256sum -c -

mount -o loop,ro "/mnt/omarchy-store/$ISO" /mnt/omarchy-iso
[ -f /mnt/omarchy-iso/boot/grub/loopback.cfg ] ||
  die "ISO is missing /boot/grub/loopback.cfg"
umount /mnt/omarchy-iso

STORE_UUID="$(blkid -s UUID -o value "$STORE")"
[ -n "$STORE_UUID" ] || die "Could not read ISO partition UUID."

echo "[7/8] Building UEFI launcher..."
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

echo "[8/8] Setting next UEFI boot..."
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
[ -n "$BOOTNUM" ] || die "Could not determine Omarchy UEFI boot entry."
efibootmgr --bootnext "$BOOTNUM"

sync
cleanup
trap - EXIT

echo "Prepared successfully. Rebooting into Omarchy installer..."
echo "Choose FREE SPACE in the Omarchy installer."
sleep 3
reboot
