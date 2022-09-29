{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.tailscale;

in
{
  options.services.tailscale = {
    domain = mkOption {
      type = types.str;
      default = "";
      description = "Your tailnet's name. This can be found on https://login.tailscale.com/admin/settings/general under General > Name.";
    };

    enable = mkEnableOption "Tailscale client daemon";

    package = mkOption {
      type = types.package;
      default = pkgs.tailscale;
      defaultText = literalExpression "pkgs.tailscale";
      description = "The package to use for tailscale";
    };

    magicDNS = {
      enable = mkEnableOption "Whether to configure networking to work with Tailscale's MagicDNS.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [ {
      assertion = !cfg.magicDNS.enable || config.networking.dns != [ "100.100.100.100" ];
      message = ''
        When MagicDNS is enabled, fallback DNS servers need to be set with `networking.dns`.

        Otherwise, Tailscale will take a long time to connect and all DNS queries
        will fail until Tailscale has connected.
      '';
    } ];

    warnings = [
      (mkIf (cfg.magicDNS.enable && cfg.domain == "") "${showOption cfg.domain} is empty, Tailscale MagicDNS search path won't be configured.")
    ];

    environment.systemPackages = [ cfg.package ];

    # derived from
    # https://github.com/tailscale/tailscale/blob/main/cmd/tailscaled/install_darwin.go#L30
    launchd.daemons.tailscaled = {
      serviceConfig = {
        Label = "com.tailscale.tailscaled";
        ProgramArguments = [
          "/bin/sh" "-c"
          "/bin/wait4path ${cfg.package} &amp;&amp; ${cfg.package}/bin/tailscaled"
        ];
        RunAtLoad = true;
      };
    };

    networking = mkIf cfg.magicDNS.enable {
      dns = [ "100.100.100.100" ];
      search =
        if cfg.domain == "" then
          [ ]
        else
          [ "${cfg.domain}.beta.tailscale.net" ];
    };
  };
}
