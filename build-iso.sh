#!/usr/bin/env bash
set -Eeuo pipefail

DEBIAN_VERSION="${DEBIAN_VERSION:-13.6.0}"
ARCH="amd64"
ISO_NAME="debian-${DEBIAN_VERSION}-${ARCH}-netinst.iso"
ISO_URL="https://cdimage.debian.org/debian-cd/current/${ARCH}/iso-cd/${ISO_NAME}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE="${ROOT}/cache"
WORK="${ROOT}/work"
MNT="${WORK}/mnt"
PATCH="${WORK}/patch"
OUTPUT="${ROOT}/output"
OUT_ISO="${OUTPUT}/echofree-amd64.iso"

for cmd in curl xorriso gzip cpio; do
  command -v "$cmd" >/dev/null || {
    echo "Missing dependency: $cmd" >&2
    exit 1
  }
done

mkdir -p "$CACHE" "$OUTPUT"
rm -rf "$WORK"
mkdir -p "$MNT" "$PATCH"

if [[ ! -f "${CACHE}/${ISO_NAME}" ]]; then
  echo "Downloading Debian ${DEBIAN_VERSION}..."
  curl -fL "$ISO_URL" -o "${CACHE}/${ISO_NAME}"
fi

cleanup() {
  mountpoint -q "$MNT" && umount "$MNT" || true
}
trap cleanup EXIT

mount -o loop,ro "${CACHE}/${ISO_NAME}" "$MNT"

# Prepare modified boot menus.
if [[ -f "${MNT}/boot/grub/grub.cfg" ]]; then
  mkdir -p "${PATCH}/boot/grub"
  cp "${MNT}/boot/grub/grub.cfg" "${PATCH}/boot/grub/grub.cfg"
  cat >> "${PATCH}/boot/grub/grub.cfg" <<'EOF'

menuentry 'Install EchoFree v0.1 (ERASE TARGET DISK)' {
    set background_color=black
    linux /install.amd/vmlinuz auto=true priority=critical file=/cdrom/preseed.cfg --- quiet
    initrd /install.amd/initrd.gz
}
EOF
fi

if [[ -f "${MNT}/isolinux/txt.cfg" ]]; then
  mkdir -p "${PATCH}/isolinux"
  cp "${MNT}/isolinux/txt.cfg" "${PATCH}/isolinux/txt.cfg"
  cat >> "${PATCH}/isolinux/txt.cfg" <<'EOF'

label echofree
    menu label ^Install EchoFree v0.1 (ERASE TARGET DISK)
    kernel /install.amd/vmlinuz
    append auto=true priority=critical file=/cdrom/preseed.cfg initrd=/install.amd/initrd.gz --- quiet
EOF
fi

# Embed preseed into installer initrds.
for rel in install.amd/initrd.gz install.amd/gtk/initrd.gz; do
  [[ -f "${MNT}/${rel}" ]] || continue
  mkdir -p "${PATCH}/$(dirname "$rel")"
  tmpdir="$(mktemp -d)"
  (
    cd "$tmpdir"
    gzip -dc "${MNT}/${rel}" | cpio -id --quiet
    cp "${ROOT}/preseed.cfg" preseed.cfg
    find . -print0 | cpio --null -o --format=newc --quiet | gzip -9 > "${PATCH}/${rel}"
  )
  rm -rf "$tmpdir"
done

umount "$MNT"

rm -f "$OUT_ISO"

# Modify the original ISO model directly. This preserves Debian's embedded
# BIOS/UEFI boot images and then replays their boot configuration.
XORRISO_ARGS=(
  -indev "${CACHE}/${ISO_NAME}"
  -outdev "$OUT_ISO"
  -map "${ROOT}/preseed.cfg" /preseed.cfg
  -map "${ROOT}/payload" /echofree
)

[[ -f "${PATCH}/boot/grub/grub.cfg" ]] &&
  XORRISO_ARGS+=( -map "${PATCH}/boot/grub/grub.cfg" /boot/grub/grub.cfg )

[[ -f "${PATCH}/isolinux/txt.cfg" ]] &&
  XORRISO_ARGS+=( -map "${PATCH}/isolinux/txt.cfg" /isolinux/txt.cfg )

[[ -f "${PATCH}/install.amd/initrd.gz" ]] &&
  XORRISO_ARGS+=( -map "${PATCH}/install.amd/initrd.gz" /install.amd/initrd.gz )

[[ -f "${PATCH}/install.amd/gtk/initrd.gz" ]] &&
  XORRISO_ARGS+=( -map "${PATCH}/install.amd/gtk/initrd.gz" /install.amd/gtk/initrd.gz )

xorriso \
  "${XORRISO_ARGS[@]}" \
  -boot_image any replay \
  -volid ECHOFREE_01 \
  -commit

test -s "$OUT_ISO"

echo
echo "Created: $OUT_ISO"
echo "Size: $(du -h "$OUT_ISO" | awk '{print $1}')"
echo "Test this in a VM before using physical hardware."
