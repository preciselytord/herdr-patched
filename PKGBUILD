# Herdr release + the patches in patches/, built from source.
# pkgver, _zigver and the checksums are rewritten by scripts/rebase.sh.
pkgname=herdr-patched
pkgver=0.9.5
pkgrel=1
_zigver=0.16.0
_zigsha=70e49664a74374b48b51e6f3fdfbf437f6395d42509050588bd49abe52ba3d00
pkgdesc="Herdr terminal multiplexer for coding agents, with extra patches (herdr app focus)"
arch=(x86_64)
url="https://github.com/preciselytord/herdr-patched"
license=(Apache-2.0)
depends=(gcc-libs glibc)
makedepends=(git rustup)
provides=("herdr=$pkgver")
conflicts=(herdr)
options=(!lto !debug)
source=("herdr::git+https://github.com/herdrdev/herdr.git#tag=v$pkgver"
        "https://ziglang.org/download/$_zigver/zig-x86_64-linux-$_zigver.tar.xz")
sha256sums=('SKIP'
            "$_zigsha")

prepare() {
  cd herdr
  git -c user.name=build -c user.email=build@localhost am -3 "$startdir"/patches/*.patch
}

_env() {
  export ZIG="$srcdir/zig-x86_64-linux-$_zigver/zig"
  export CARGO_HOME="$srcdir/cargo-home"
  export RUSTFLAGS="${RUSTFLAGS:-} --remap-path-prefix=$srcdir=/build"
  export RUSTUP_TOOLCHAIN=$(sed -n 's/^channel *= *"\(.*\)"/\1/p' "$srcdir/herdr/rust-toolchain.toml")
  rustup toolchain install --profile minimal "$RUSTUP_TOOLCHAIN" >/dev/null
}

build() {
  cd herdr
  _env
  cargo build --release --locked
}

# Tests run separately (scripts/test.sh) on a plain host, as upstream CI does;
# several upstream tests need ssh and real process reaping a build chroot lacks.

package() {
  cd herdr
  install -Dm755 target/release/herdr "$pkgdir/usr/bin/herdr"
  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
