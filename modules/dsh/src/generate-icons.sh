#!/usr/bin/env bash
set -euo pipefail

src="$1"
sizes=(512 128 16 22 24 256 32 48 64 96)

[[ -f "$src" ]] || { echo "source not found: $src" >&2; exit 1; }
command -v magick >/dev/null || { echo "ImageMagick 7 'magick' required" >&2; exit 1; }

for size in "${sizes[@]}"; do
  dir="$HOME/.local/share/icons/hicolor/${size}x${size}/apps"
  out="$dir/${src##*/}"
  mkdir -p "$dir"

  magick "$src" \
    -auto-orient \
    -strip \
    -filter Lanczos \
    -resize "${size}x${size}" \
    -define png:compression-level=9 \
    -define png:compression-filter=5 \
    -define png:compression-strategy=1 \
    "$out"

  echo "wrote $out"
done

xdg-icon-resource forceupdate --theme hicolor
