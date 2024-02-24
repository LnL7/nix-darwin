{ config, lib, ... }:
let
  anyEnabled = lib.any (cfg: cfg.enable) (lib.attrValues config.services.github-runners);
in
{
  imports = [
    ./options.nix
    ./config.nix
  ];

  config.assertions = lib.mkIf anyEnabled [
    {
      assertion = lib.elem "github-runner" config.users.knownGroups;
      message = "set `users.knownGroups` to enable `github-runner` group";
    }
    {
      assertion = lib.elem "github-runner" config.users.knownUsers;
      message = "set `users.knownUsers` to enable `github-runner` user";
    }
  ];

  config.users = lib.mkIf anyEnabled {
    users."github-runner" = {
      createHome = true;
      uid = lib.mkDefault 533;
      gid = lib.mkDefault config.users.groups.github-runner.gid;
      home = lib.mkDefault "/var/lib/github-runners";
      shell = "/bin/bash";
      description = "GitHub Runner service user";
    };

    groups."github-runner" = {
      gid = lib.mkDefault 533;
      description = "GitHub Runner service user group";
    };
  };
}
