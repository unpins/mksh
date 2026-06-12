# mksh via cosmoStaticCross (= pkgs.pkgsCross.cosmo) for Windows-x86_64.
#
# cosmocc backs fork/job-control/signals, which a Korn shell needs and mingw
# cannot provide. The cosmo cross stdenv auto-apelinks $out/bin/* (ELF -> PE32+,
# rename to <name>.exe) in fixupPhase.
#
# mksh builds with its own Build.sh (not autoconf), which feature-detects by
# compiling and *running* tiny probe programs. That works under the cosmo cross
# because a cosmocc-built APE runs natively on the x86_64-linux build host — so
# Build.sh's probes execute and report cosmo's real capabilities.
{ unpins-lib }:
pkgs:
let
  cosmoPkgs = unpins-lib.lib.cosmoStaticCross pkgs;
in
cosmoPkgs.mksh
