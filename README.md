# herdr-patched

Stable [Herdr](https://github.com/herdrdev/herdr) releases plus a small set of
patches, built from source and published as a pacman repository. It is not a
fork: this repo holds only the patches, a PKGBUILD and the release workflow.

## Patches

| Patch | What it adds | Origin |
|---|---|---|
| `0001-feat-add-an-external-activate-endpoint-trigger-for-t.patch` | `herdr app focus [--machine <label>] --pane/--tab/--workspace <id>` and the `client.activate_endpoint` API: switch the running window to a saved machine and focus a target there. Upstream discussion: [herdrdev/herdr#4396](https://github.com/herdrdev/herdr/discussions/4396). | Backport of [arrrrny/herdr@0aa31c6a](https://github.com/arrrrny/herdr/commit/0aa31c6a) to v0.9.5, code and tests only (no docs). |

Only the machine running the Herdr window needs this build. Saved machines can
stay on stock Herdr: the new hello field is optional and stock servers ignore it.

## Install (Arch / Omarchy)

Add the repository to `/etc/pacman.conf`:

```ini
[herdr-patched]
SigLevel = Optional TrustAll
Server = https://github.com/preciselytord/herdr-patched/releases/download/repo
```

Then swap the stock package (pacman asks to remove `herdr`):

```sh
sudo pacman -Syu herdr-patched
```

Restart Herdr to load the new binary. From then on `omarchy-update` (plain
`pacman -Syu`) installs new builds. To go back: `sudo pacman -S herdr`.

The packages are unsigned; trust rests on HTTPS and this GitHub repository.

## How releases happen

`.github/workflows/release.yml` runs every night:

1. If `herdrdev/herdr` has a new stable release (`vX.Y.Z`, no previews),
   `scripts/rebase.sh` replays `patches/` onto the new tag and picks up the Zig
   version upstream builds with (checksum from ziglang.org).
2. `scripts/test.sh` runs upstream's full test suite with the patches applied,
   on a plain Ubuntu runner with cargo-nextest, the way upstream CI does.
3. `scripts/build.sh` runs `makepkg` in `archlinux:base-devel` and `repo-add`.
4. On success it commits the rebased patches and replaces the files on the
   `repo` release. On any failure it opens an issue and publishes nothing, so
   installed machines stay on the last good build.

It also runs on pushes to `patches/`, `PKGBUILD` or `scripts/`, and by hand.
Bump `pkgrel` when you change a patch without a new upstream release.

## Local build

```sh
scripts/test.sh             # upstream tests with the patches (needs cargo-nextest)
scripts/build.sh            # out/ holds the package and the repo database
scripts/rebase.sh v0.9.6    # move the patches to another release
```

## License

Apache-2.0, as upstream Herdr. The patch keeps its original author.
