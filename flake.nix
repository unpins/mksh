{
  description = "mksh (the MirBSD Korn Shell) as a single self-contained binary";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # mksh (the MirBSD Korn Shell) as a single self-contained static binary.
  # This is the cleanest shell in the catalog so far: it has its own line
  # editor (no ncurses/terminfo), uses no NLS catalogs (no catgets), and ships
  # no autoloaded function/completion tree. stock pkgsStatic.mksh already runs
  # static with a closure of exactly itself, zero /nix/store strings, and zero
  # runtime store reads — so the only deltas vs nixpkgs are the standard
  # man-page embed (done by mkStandaloneFlake) and the Windows/Cosmopolitan
  # build (see cosmo.nix).
  #
  # The sample rc file nixpkgs installs to share/mksh/mkshrc is NOT required at
  # runtime (mksh has built-in defaults); it is dropped from the standalone
  # binary, which carries only the executable + embedded man page.
  #
  # Targets:
  #   - Linux (static-musl, every arch).
  #   - macOS (Mach-O, libSystem-only).
  #   - Windows (single PE .exe, built via Cosmopolitan): see cosmo.nix.
  outputs = { self, unpins-lib }:
    unpins-lib.lib.mkStandaloneFlake {
      inherit self;
      name = "mksh";

      # Build via the unpin-llvm engine + emit a bitcode multicall module.
      engine = "unpin-llvm";
      multicall = {
        programs = [{ name = "mksh"; }];
      };
      license = "MirOS";

      # mksh has -c; exercise the interpreter and a builtin to confirm argv
      # parsing on every ABI (incl. the cosmo APE).
      smoke = [ "-c" "echo unpins-smoke-ok" ];
      smokePattern = "unpins-smoke-ok";

      windowsBuild = import ./cosmo.nix { inherit unpins-lib; };

      build = pkgs: pkgs.pkgsStatic.mksh;
    };
}
