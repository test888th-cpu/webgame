#!/usr/bin/env bash
# Installs the pinned Godot editor binary (and optionally the web export
# templates), verifying both against hashes recorded in this script.
#
#   tools/ci/install-godot.sh <install-dir> [--with-web-templates]
#
# To upgrade Godot: change GODOT_VERSION, copy the two matching lines from the
# release's SHA512-SUMS.txt, and follow the upgrade notes in CONTRIBUTING.md.
set -euo pipefail

GODOT_VERSION="4.7.2"
EDITOR_SHA512="9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65"
TEMPLATES_SHA512="ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079"

dest="${1:?usage: install-godot.sh <install-dir> [--with-web-templates]}"
base="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

mkdir -p "$dest"
if [[ ! -x "$dest/godot" ]]; then
  curl -fsSL --retry 3 -o "$work/godot.zip" "$base/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
  echo "$EDITOR_SHA512  $work/godot.zip" | sha512sum -c --quiet
  unzip -q "$work/godot.zip" -d "$work"
  mv "$work/Godot_v${GODOT_VERSION}-stable_linux.x86_64" "$dest/godot"
  chmod +x "$dest/godot"
fi

if [[ "${2:-}" == "--with-web-templates" ]]; then
  tpl_dir="$HOME/.local/share/godot/export_templates/${GODOT_VERSION}.stable"
  if [[ ! -f "$tpl_dir/web_nothreads_release.zip" ]]; then
    curl -fsSL --retry 3 -o "$work/templates.tpz" "$base/Godot_v${GODOT_VERSION}-stable_export_templates.tpz"
    echo "$TEMPLATES_SHA512  $work/templates.tpz" | sha512sum -c --quiet
    # Only the web templates are needed; the full archive is ~1.3 GB.
    unzip -q "$work/templates.tpz" 'templates/web_*' 'templates/version.txt' -d "$work"
    mkdir -p "$tpl_dir"
    mv "$work"/templates/* "$tpl_dir/"
  fi
fi

"$dest/godot" --headless --version
