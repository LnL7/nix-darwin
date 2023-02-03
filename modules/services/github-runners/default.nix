{ config
, pkgs
, lib
, ...
}@args:

with lib;

let
  cfg = config.services.github-runners;
in

{
  options.services.github-runners = mkOption {
    default = {};
    type = with types;
      attrsOf (submodule { options = import ./options.nix args; });
    example = {
      runner1 = {
        url = "https://github.com/owner/repo";
        name = "runner1";
        tokenFile = "/secrets/token1";
      };

      runner2 = {
        url = "https://github.com/owner/repo";
        name = "runner2";
        tokenFile = "/secrets/token2";
      };
    };
    description = lib.mdDoc ''
      GitHub Actions runners.

      Note: GitHub recommends using self-hosted runners with private repositories only. Learn more here:
      [About self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners).
    '';
  };

  config = {
    # create a launchd service for each gtihub runner
    launchd.daemons = flip mapAttrs' cfg (name: runnerConfig:
      let
        svcName = name;
      in
        nameValuePair svcName
        (import ./service.nix (args // {
          inherit svcName;
          cfg = runnerConfig;
        }))
    );

    users.knownGroups = ["github-runner"];
    users.knownUsers = ["github-runner"];
    users.users.github-runner = {
      name = "github-runner";
      uid = mkDefault 533;
      # gid = mkDefault config.users.groups.gitlab-runner.gid;
      home = mkDefault "/var/lib/github-runner";
      createHome = true;
      shell = "/bin/bash";
      description = "Github runner users";
    };
    users.groups.github-runner = {
      name = "github-runner";
      gid = mkDefault 533;
      description = "Github runner user group";
    };
  };
}
