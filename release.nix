{ nixpkgs ? <nixpkgs>
, supportedSystems ? [ "x86_64-darwin" ]
, scrubJobs ? true
}:

let

  inherit (release) mapTestOn packagePlatforms pkgs;

  genExample = configuration: pkgs.lib.genAttrs [ "x86_64-darwin" ] (system:
    (import ./. { pkgs = import nixpkgs { inherit system; }; inherit configuration; }).system
  );

  release = import <nixpkgs/pkgs/top-level/release-lib.nix> {
    inherit supportedSystems scrubJobs;
    packageSet = import nixpkgs;
  };

  packageSet = {
    inherit (pkgs) stdenv bash zsh nix nix-repl vim tmux reattach-to-user-namespace;
  };

  jobs = {

    inherit jobs release pkgs;

    unstable = pkgs.releaseTools.aggregate {
      name = "darwin-${pkgs.lib.nixpkgsVersion}";
      constituents =
        [ jobs.stdenv.x86_64-darwin
          jobs.bash.x86_64-darwin
          jobs.lnl.x86_64-darwin
          jobs.simple.x86_64-darwin
        ];
      meta.description = "Release-critical builds for the Nixpkgs unstable channel";
    };

    examples.lnl = genExample ./modules/examples/lnl.nix;
    examples.simple = genExample ./modules/examples/simple.nix;

  }
  // (mapTestOn (packagePlatforms packageSet));

in

  jobs
