# mksh via cosmoStaticCross (= pkgs.pkgsCross.cosmo) for Windows-x86_64.
#
# cosmocc backs fork/job-control/signals, which a Korn shell needs and mingw
# cannot provide. The cosmo cross stdenv auto-apelinks $out/bin/* (ELF -> PE32+,
# rename to <name>.exe) in fixupPhase.
#
# One cosmo-specific fix. mksh is security-minded (MirBSD) and its Build.sh
# probes for and enables `-fstack-protector-strong`. On a normal target that's
# fine, but the canary it emits is read from `%fs:0x28` (the glibc/musl TLS
# convention). On Windows %fs holds the TEB, not the stack guard, so that load
# faults the instant any protected function runs — the binary SIGSEGVs during
# startup before main produces any output (confirmed on real Windows via
# `--strace`: the faulting instruction is `mov %fs:0x28,%rcx`). cosmo handles
# stack protection with a global guard, not a %fs-relative one, so the two are
# incompatible. Disable the stack protector on the cosmo build (appended last,
# so it overrides mksh's own `-fstack-protector-strong`); the other targets keep
# it. The autoconf shells (dash/tcsh/oksh/zsh) never hit this because they don't
# force the flag the way mksh's Build.sh does.
{ unpins-lib }:
pkgs:
let
  cosmoPkgs = unpins-lib.lib.cosmoStaticCross pkgs;
in
cosmoPkgs.mksh.overrideAttrs (oa: {
  # Windows command lookup: catalog programs install as `<name>.exe` hardlinks
  # (cmd.exe/PowerShell find them via PATHEXT), but Cosmopolitan does not append
  # an executable suffix during path resolution, so a bare `ls` typed at the mksh
  # prompt never resolves. The patch teaches mksh's PATH search (search_path) to
  # retry a candidate with `.exe` when the bare name is missing — mirroring native
  # Windows shells and keeping a single on-disk name (no `ls` + `ls.exe` pair).
  # `__COSMOCC__`-guarded, inert on the Linux/macOS static builds. See
  # docs/platforms/cosmocc.md.
  postPatch = (oa.postPatch or "") + ''
    patch -p1 < ${./findcmd-exe-lookup.patch}
  '';

  env = (oa.env or { }) // {
    NIX_CFLAGS_COMPILE = builtins.concatStringsSep " " [
      (oa.env.NIX_CFLAGS_COMPILE or "")
      "-fno-stack-protector"
    ];
  };
})
