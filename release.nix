{ nixpkgs ? <nixpkgs>
, supportedSystems ? [ "x86_64-darwin" ]
, scrubJobs ? true
}:

let

  inherit (release) mapTestOn packagePlatforms pkgs all linux darwin;

  mapPlatforms = systems: pkgs.lib.mapAttrs (n: v: systems);

  genExample = configuration: pkgs.lib.genAttrs [ "x86_64-darwin" ] (system:
    (import ./. { inherit nixpkgs configuration system; }).system
  );

  release = import <nixpkgs/pkgs/top-level/release-lib.nix> {
    inherit supportedSystems scrubJobs;
    packageSet = import nixpkgs;
  };

  packageSet = {
    # stdenv
    inherit (pkgs)
      autoconf automake bison bzip2 clang cmake coreutils cpio ed findutils flex gawk gettext gmp
      gnugrep gnum4 gnumake gnused groff gzip help2man libcxx libcxxabi libedit libffi libtool
      libxml2 llvm ncurses patch pcre perl pkgconfig python unzip xz zlib;
    perlPackages = { inherit (pkgs.perlPackages) LocaleGettext; };
    darwin = {
      inherit (pkgs.darwin)
        CF CarbonHeaders CommonCrypto Csu IOKit Libinfo Libm Libnotify Libsystem adv_cmds
        architecture bootstrap_cmds bsdmake cctools configd copyfile dyld eap8021x launchd
        libclosure libdispatch libiconv libpthread libresolv libutil objc4 ppp removefile xnu;
    };

    inherit (pkgs)
      stdenv bash zsh nix nix-repl nano vim emacs tmux reattach-to-user-namespace;
  };

  jobs = {

    unstable = pkgs.releaseTools.aggregate {
      name = "darwin-${pkgs.lib.nixpkgsVersion}";
      constituents =
        [ jobs.stdenv.x86_64-darwin
          jobs.bash.x86_64-darwin
          jobs.zsh.x86_64-darwin
          jobs.nix-repl.x86_64-darwin
          jobs.nix.x86_64-darwin
          jobs.reattach-to-user-namespace.x86_64-darwin
          jobs.tmux.x86_64-darwin
          jobs.nano.x86_64-darwin
          jobs.vim.x86_64-darwin
          jobs.emacs.x86_64-darwin
          jobs.examples.lnl.x86_64-darwin
          jobs.examples.simple.x86_64-darwin
        ];
      meta.description = "Release-critical builds for the darwin unstable channel";
    };

    examples.lnl = genExample ./modules/examples/lnl.nix;
    examples.simple = genExample ./modules/examples/simple.nix;

  }
  // (mapTestOn (packagePlatforms packageSet))
  // (mapTestOn { perlPackages = mapPlatforms all packageSet.perlPackages; })
  // (mapTestOn { darwin = mapPlatforms darwin packageSet.darwin; });

in

  jobs
