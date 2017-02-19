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
    inherit (pkgs)
      stdenv bash zsh nix nix-repl
      tmux reattach-to-user-namespace
      nano emacs vim;
  };

  jobs = {

    unstable = pkgs.releaseTools.aggregate {
      name = "darwin-${pkgs.lib.nixpkgsVersion}";
      constituents =
        [ jobs.stdenv.x86_64-darwin
          jobs.bash.x86_64-darwin
          jobs.zsh.x86_64-darwin
          jobs.nix.x86_64-darwin
          jobs.nix-repl.x86_64-darwin
          # jobs.reattach-to-user-namespace.x86_64-darwin license?
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
  // (mapTestOn (packagePlatforms packageSet));

in

  jobs
