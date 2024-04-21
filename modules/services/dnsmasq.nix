{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.dnsmasq;
  mapA = f: attrs: with builtins; attrValues (mapAttrs f attrs);
in

{
  options = {
    services.dnsmasq.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable DNSmasq.";
    };

    services.dnsmasq.package = mkOption {
      type = types.path;
      default = pkgs.dnsmasq;
      defaultText = "pkgs.dnsmasq";
      description = "This option specifies the dnsmasq package to use.";
    };

    services.dnsmasq.bind = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "This option specifies the interface on which DNSmasq will listen.";
    };

    services.dnsmasq.port = mkOption {
      type = types.int;
      default = 53;
      description = "This option specifies port on which DNSmasq will listen.";
    };

    services.dnsmasq.addresses = mkOption {
      type = types.attrs;
      default = {};
      description = "List of domains that will be redirected by the DNSmasq.";
      example = literalExpression ''
        { localhost = "127.0.0.1"; }
        '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    launchd.daemons.dnsmasq = {
      serviceConfig.ProgramArguments = [
        "${cfg.package}/bin/dnsmasq"
        "--listen-address=${cfg.bind}"
        "--port=${toString cfg.port}"
        "--keep-in-foreground"
      ] ++ (mapA (domain: addr: "--address=/${domain}/${addr}") cfg.addresses);

      serviceConfig.KeepAlive = true;
      serviceConfig.RunAtLoad = true;
    };

    environment.etc = builtins.listToAttrs (builtins.map (domain: {
      name = "resolver/${domain}";
      value = {
        enable = true;
        text = ''
          port ${toString cfg.port}
          nameserver ${cfg.bind}
          '';
      };
    }) (builtins.attrNames cfg.addresses));
  };
}
