{ nixpkgs ? <nixpkgs>
, supportedSystems ? [ "x86_64-darwin" ]
, scrubJobs ? true
}:

let
  inherit (release) mapTestOn packagePlatforms pkgs all linux darwin;

  system = "x86_64-darwin";

  mapPlatforms = systems: pkgs.lib.mapAttrs (n: v: systems);

  buildFromConfig = configuration: sel: sel
    (import ./. { inherit nixpkgs configuration system; }).config;

  makeSystem = configuration: pkgs.lib.genAttrs [ system ] (system:
    buildFromConfig configuration (config: config.system.build.toplevel)
  );

  makeTest = test:
    let
      testName =
        builtins.replaceStrings [ ".nix" ] [ "" ]
          (builtins.baseNameOf test);

      configuration =
        { config, lib, pkgs, ... }:
        with lib;
        {
          imports = [ test ];

          options = {
            out = mkOption {
              type = types.package;
            };

            test = mkOption {
              type = types.lines;
            };
          };

          config = {
            system.build.run-test = pkgs.runCommand "darwin-test-${testName}"
              { allowSubstitutes = false; preferLocalBuild = true; }
              ''
                #! ${pkgs.stdenv.shell}
                set -e

                echo >&2 "running tests for system ${config.out}"
                echo >&2
                ${config.test}
                echo >&2 ok
                touch $out
              '';

            out = config.system.build.toplevel;
          };
        };
    in
      buildFromConfig configuration (config: config.system.build.run-test);

  release = import <nixpkgs/pkgs/top-level/release-lib.nix> {
    inherit supportedSystems scrubJobs;
    packageSet = import nixpkgs;
  };

  packageSet = {
    inherit (pkgs)
      stdenv bash zsh nix
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
          jobs.reattach-to-user-namespace.x86_64-darwin
          jobs.tmux.x86_64-darwin
          jobs.nano.x86_64-darwin
          jobs.vim.x86_64-darwin
          jobs.emacs.x86_64-darwin
          jobs.examples.hydra.x86_64-darwin
          jobs.examples.lnl.x86_64-darwin
          jobs.examples.simple.x86_64-darwin
        ];
      meta.description = "Release-critical builds for the darwin channel";
    };

    manualHTML = buildFromConfig ({ ... }: { }) (config: config.system.build.manual.manualHTML);
    manpages = buildFromConfig ({ ... }: { }) (config: config.system.build.manual.manpages);
    options = buildFromConfig ({ ... }: { }) (config: config.system.build.manual.optionsJSON);

    examples.hydra = makeSystem ./modules/examples/hydra.nix;
    examples.lnl = makeSystem ./modules/examples/lnl.nix;
    examples.simple = makeSystem ./modules/examples/simple.nix;

    tests.activation-scripts = makeTest ./tests/activation-scripts.nix;
    tests.autossh = makeTest ./tests/autossh.nix;
    tests.checks-nix-gc = makeTest ./tests/checks-nix-gc.nix;
    tests.checks-nh-clean = makeTest ./tests/checks-nh-clean.nix;
    tests.environment-path = makeTest ./tests/environment-path.nix;
    tests.environment-terminfo = makeTest ./tests/environment-terminfo.nix;
    tests.homebrew = makeTest ./tests/homebrew.nix;
    tests.launchd-daemons = makeTest ./tests/launchd-daemons.nix;
    tests.launchd-setenv = makeTest ./tests/launchd-setenv.nix;
    tests.networking-hostname = makeTest ./tests/networking-hostname.nix;
    tests.networking-networkservices = makeTest ./tests/networking-networkservices.nix;
    tests.nixpkgs-overlays = makeTest ./tests/nixpkgs-overlays.nix;
    tests.programs-nh = makeTest ./tests/programs-nh.nix;
    tests.programs-ssh = makeTest ./tests/programs-ssh.nix;
    tests.programs-tmux = makeTest ./tests/programs-tmux.nix;
    tests.programs-zsh = makeTest ./tests/programs-zsh.nix;
    tests.programs-ssh-empty-known-hosts = makeTest ./tests/programs-ssh-empty-known-hosts.nix;
    tests.security-pki = makeTest ./tests/security-pki.nix;
    tests.services-activate-system = makeTest ./tests/services-activate-system.nix;
    tests.services-activate-system-changed-label-prefix = makeTest ./tests/services-activate-system-changed-label-prefix.nix;
    tests.services-buildkite-agent = makeTest ./tests/services-buildkite-agent.nix;
    tests.services-github-runners = makeTest ./tests/services-github-runners.nix;
    tests.services-lorri = makeTest ./tests/services-lorri.nix;
    tests.services-nix-daemon = makeTest ./tests/services-nix-daemon.nix;
    tests.sockets-nix-daemon = makeTest ./tests/sockets-nix-daemon.nix;
    tests.services-dnsmasq = makeTest ./tests/services-dnsmasq.nix;
    tests.services-eternal-terminal = makeTest ./tests/services-eternal-terminal.nix;
    tests.services-nix-gc = makeTest ./tests/services-nix-gc.nix;
    tests.services-nix-optimise = makeTest ./tests/services-nix-optimise.nix;
    tests.services-nextdns = makeTest ./tests/services-nextdns.nix;
    tests.services-ofborg = makeTest ./tests/services-ofborg.nix;
    tests.services-offlineimap = makeTest ./tests/services-offlineimap.nix;
    tests.services-privoxy = makeTest ./tests/services-privoxy.nix;
    tests.services-redis = makeTest ./tests/services-redis.nix;
    tests.services-skhd = makeTest ./tests/services-skhd.nix;
    tests.services-spacebar = makeTest ./tests/services-spacebar.nix;
    tests.services-spotifyd = makeTest ./tests/services-spotifyd.nix;
    tests.services-synapse-bt = makeTest ./tests/services-synapse-bt.nix;
    tests.services-synergy = makeTest ./tests/services-synergy.nix;
    tests.services-yabai = makeTest ./tests/services-yabai.nix;
    tests.system-defaults-write = makeTest ./tests/system-defaults-write.nix;
    tests.system-environment = makeTest ./tests/system-environment.nix;
    tests.system-keyboard-mapping = makeTest ./tests/system-keyboard-mapping.nix;
    tests.system-packages = makeTest ./tests/system-packages.nix;
    tests.system-path = makeTest ./tests/system-path.nix;
    tests.system-shells = makeTest ./tests/system-shells.nix;
    tests.users-groups = makeTest ./tests/users-groups.nix;
    tests.users-packages = makeTest ./tests/users-packages.nix;
    tests.fonts = makeTest ./tests/fonts.nix;

  }
  // (mapTestOn (packagePlatforms packageSet));

in
  jobs
