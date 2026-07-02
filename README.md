# mksh

[mksh](http://www.mirbsd.org/mksh.htm) — the MirBSD Korn Shell, a modern,
DFSG-free successor to the Public Domain Korn Shell (pdksh) with a command-line
editor, vi/emacs editing modes, arrays, arithmetic, and job control. A single
self-contained binary, built natively for Linux, macOS, and Windows.

[![CI](https://github.com/unpins/mksh/actions/workflows/mksh.yml/badge.svg)](https://github.com/unpins/mksh/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-✓-success?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-✓-success?logo=windows&logoColor=white)

Part of the [unpins](https://unpins.org) catalog; install it with [`unpin`](https://github.com/unpins/unpin): `unpin install mksh`.

## Usage

Run `mksh` with [unpin](https://github.com/unpins/unpin):

```bash
unpin mksh                        # start an interactive shell
unpin mksh script.ksh             # run a script
unpin mksh -c 'echo $KSH_VERSION'
```

To install it onto your PATH:

```bash
unpin install mksh
```

mksh is a Korn shell, so the usual ksh features work out of the box — arrays,
`typeset`, arithmetic `$(( ))`, and the `print` builtin:

```ksh
set -A fruit apple banana cherry
echo ${fruit[1]} ${#fruit[*]}     # banana 3
typeset -i n=6; echo $((n * 7))   # 42
```

## Man pages

The mksh manual (`mksh.1`) is embedded, so `unpin man mksh` works offline.

## Build locally

```bash
nix build github:unpins/mksh
./result/bin/mksh -c 'echo $KSH_VERSION'
```

Or run directly:

```bash
nix run github:unpins/mksh -- -c 'echo hello from mksh'
```

The first invocation will offer to add the [unpins.cachix.org](https://unpins.cachix.org) substituter so most pulls come pre-built.

## Manual download

The [Releases](https://github.com/unpins/mksh/releases) page has standalone binaries for manual download.

## Build notes

- **Self-contained, nothing to embed.** mksh is the cleanest shell in the
  catalog: it has its own line editor (no ncurses/terminfo), uses no NLS message
  catalogs, and has no module or autoloaded-function tree. The upstream static
  build already links to nothing but itself and reads no files from the Nix
  store at runtime, so the standalone binary is just the executable plus its
  embedded man page — no patches required. The sample `mkshrc` that some
  distributions ship is a user dotfile, not needed at runtime, and is omitted.

- **Static linking, every target.** Linux is static-musl on every architecture;
  macOS links only `libSystem` (`otool -L` confirms). Both run with an empty
  environment and read nothing from `/nix/store`.

- **Windows via Cosmopolitan.** mingw can't host a Korn shell (no `fork`, job
  control, or POSIX signals), so the Windows binary goes through cosmo. mksh's
  own `Build.sh` feature-detection works unchanged because a cosmocc-built probe
  runs natively on the build host, and it ships as a single Windows `.exe`. See
  `cosmo.nix`.

- **Tests.** mksh's `check.pl` harness isn't wired into the build: it needs
  category flags plus a writable scratch area and hits `Permission denied`
  unlinking temp/history files in the Nix build sandbox. The release smoke test
  exercises the interpreter and a builtin instead.
