#!/usr/bin/env bash
# Move patches/ and PKGBUILD from the current Herdr release to a new one.
#   scripts/rebase.sh v0.9.6
# Exits non-zero, leaving the repo untouched, when a patch no longer applies.
set -euo pipefail
cd "$(dirname "$0")/.."

new_tag=$1
new_ver=${new_tag#v}
old_ver=$(sed -n 's/^pkgver=//p' PKGBUILD)
[[ $new_ver == "$old_ver" ]] && { echo "already on $new_ver"; exit 0; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
git clone -q --filter=blob:none https://github.com/herdrdev/herdr.git "$work/herdr"
cd "$work/herdr"
git -c advice.detachedHead=false checkout -q "v$old_ver"
git -c user.name=build -c user.email=build@localhost am -q -3 "$OLDPWD"/patches/*.patch
git -c user.name=build -c user.email=build@localhost rebase -q --onto "$new_tag" "v$old_ver"
rm -f "$OLDPWD"/patches/*.patch
git format-patch -q --zero-commit --no-signature "$new_tag..HEAD" -o "$OLDPWD/patches"

# Zig version the upstream release builds with, verified against ziglang.org.
zigver=$(grep -h -A2 'setup-zig@' .github/workflows/*.yml | sed -n 's/.*version: *//p' | sort -u)
[[ $(wc -l <<<"$zigver") == 1 ]] || { echo "ambiguous zig version: $zigver" >&2; exit 1; }
cd "$OLDPWD"
zigsha=$(curl -fsSL https://ziglang.org/download/index.json | jq -r --arg v "$zigver" '.[$v]."x86_64-linux".shasum')
[[ $zigsha =~ ^[0-9a-f]{64}$ ]] || { echo "no checksum for zig $zigver" >&2; exit 1; }

sed -i -e "s/^pkgver=.*/pkgver=$new_ver/" -e "s/^pkgrel=.*/pkgrel=1/" \
       -e "s/^_zigver=.*/_zigver=$zigver/" -e "s/^_zigsha=.*/_zigsha=$zigsha/" PKGBUILD
echo "rebased onto $new_tag (zig $zigver)"
