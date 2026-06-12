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
  env = (oa.env or { }) // {
    NIX_CFLAGS_COMPILE = builtins.concatStringsSep " " [
      (oa.env.NIX_CFLAGS_COMPILE or "")
      "-fno-stack-protector"
    ];
  };
})
