#!/usr/bin/env bash
# Apply patches/ to the release named in PKGBUILD and run upstream's test suite
# the way upstream CI does (cargo nextest on a plain Linux host, not a container).
set -euo pipefail
cd "$(dirname "$0")/.."
repo=$PWD
eval "$(grep -E '^(pkgver|_zigver|_zigsha)=' PKGBUILD)"

work=${WORK:-$(mktemp -d)}
mkdir -p "$work"
if [[ ! -x $work/zig/zig ]]; then
  curl -fsSL "https://ziglang.org/download/$_zigver/zig-x86_64-linux-$_zigver.tar.xz" -o "$work/zig.tar.xz"
  echo "$_zigsha  $work/zig.tar.xz" | sha256sum -c --quiet
  mkdir -p "$work/zig" && tar xf "$work/zig.tar.xz" -C "$work/zig" --strip-components=1
fi
export ZIG=$work/zig/zig

rm -rf "$work/herdr"
git -c advice.detachedHead=false clone -q --depth 1 --branch "v$pkgver" https://github.com/herdrdev/herdr.git "$work/herdr"
cd "$work/herdr"
git -c user.name=build -c user.email=build@localhost am -q -3 "$repo"/patches/*.patch

# The patches leave docs/ alone; regenerate the API schema artifact first.
HERDR_UPDATE_API_SCHEMA=1 cargo test --locked --bin herdr -- generated_protocol_schema_artifact_is_current >/dev/null
cargo nextest run --locked --retries 2 --no-fail-fast \
  --status-level fail --final-status-level flaky --failure-output final
