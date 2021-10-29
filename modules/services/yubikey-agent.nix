{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    services.yubikey-agent.enable = mkEnableOption "yubikey-agent";

    services.yubikey-agent.package = mkOption {
      default = pkgs.yubikey-agent;
      defaultText = "pkgs.yubikey-agent";
      description = "Which yubikey-agent derivation to use";
      type = types.package;
    };
  };

  config = mkIf config.services.yubikey-agent.enable {
    environment.systemPackages = [ config.services.yubikey-agent.package ];

    launchd.user.agents.yubikey-agent = {
      path = [ config.environment.systemPath ];
      command =
        "${config.services.yubikey-agent.package}/bin/yubikey-agent -l /tmp/yubikey-agent.sock";
      serviceConfig.KeepAlive = true;
    };

    environment.extraInit = ''
      export SSH_AUTH_SOCK="/tmp/yubikey-agent.sock"
    '';
  };
}
