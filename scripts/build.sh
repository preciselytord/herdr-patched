#!/usr/bin/env bash
# Build the package and a one-package pacman repo into out/.
# Runs inside archlinux:base-devel as root (CI) or on an Arch host as a user.
set -euo pipefail
cd "$(dirname "$0")/.."
rm -rf out && mkdir -p out

if [[ $EUID == 0 ]]; then
  pacman -Syu --noconfirm --needed git rustup jq >/dev/null
  id builder >/dev/null 2>&1 || useradd -m builder
  chown -R builder: .
  su builder -c 'makepkg --noconfirm --cleanbuild'
else
  makepkg --noconfirm --cleanbuild
fi

mv ./*.pkg.tar.zst out/
cd out
repo-add -q herdr-patched.db.tar.gz ./*.pkg.tar.zst
# GitHub release assets cannot be symlinks; ship real files under pacman's names.
cp -L herdr-patched.db.tar.gz herdr-patched.db
cp -L herdr-patched.files.tar.gz herdr-patched.files
rm -f ./*.tar.gz ./*.old
ls -la
