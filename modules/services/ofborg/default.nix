{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.ofborg;
  user = config.users.users.ofborg;
in

{
  options = {
    services.ofborg.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the ofborg builder service.";
    };

    services.ofborg.package = mkOption {
      type = types.package;
      example = literalExpression "pkgs.ofborg";
      description = ''
        This option specifies the ofborg package to use. eg.

        (import &lt;ofborg&gt; {}).ofborg.rs

        $ nix-channel --add https://github.com/NixOS/ofborg/archive/released.tar.gz ofborg
        $ nix-channel --update
      '';
    };

    services.ofborg.configFile = mkOption {
      type = types.path;
      description = ''
        Configuration file to use for ofborg.

        WARNING Don't use a path literal or derivation for this,
        that would expose credentials in the store making them world readable.
      '';
    };

    services.ofborg.logFile = mkOption {
      type = types.path;
      default = "/var/log/ofborg.log";
      description = "Whether to enable the khd window manager.";
    };
  };

  config = mkIf cfg.enable {

    assertions = [
      { assertion = elem "ofborg" config.users.knownGroups; message = "set users.knownGroups to enable ofborg group"; }
      { assertion = elem "ofborg" config.users.knownUsers; message = "set users.knownUsers to enable ofborg user"; }
    ];

    warnings = mkIf (isDerivation cfg.configFile) [
      "services.ofborg.configFile is a derivation, credentials will be world readable"
    ];

    services.ofborg.configFile = mkDefault "${user.home}/config.json";

    launchd.daemons.ofborg = {
      script = ''
        git config --global user.email "ofborg@example.com"
        git config --global user.name "OfBorg"

        exec ${cfg.package}/bin/builder "${cfg.configFile}"
      '';

      path = [ config.nix.package pkgs.bash pkgs.coreutils pkgs.curl pkgs.git ];
      environment =
        { RUST_BACKTRACE = "1";
          NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        };

      serviceConfig.KeepAlive = true;
      serviceConfig.StandardErrorPath = cfg.logFile;
      serviceConfig.StandardOutPath = cfg.logFile;

      serviceConfig.GroupName = "ofborg";
      serviceConfig.UserName = "ofborg";
      serviceConfig.WorkingDirectory = user.home;
    };

    users.users.ofborg.uid = mkDefault 531;
    users.users.ofborg.gid = mkDefault config.users.groups.ofborg.gid;
    users.users.ofborg.home = mkDefault "/var/lib/ofborg";
    users.users.ofborg.shell = "/bin/bash";
    users.users.ofborg.description = "OfBorg service user";

    users.groups.ofborg.gid = mkDefault 531;
    users.groups.ofborg.description = "Nix group for OfBorg service";

    # FIXME: create logfiles automatically if defined.
    system.activationScripts.preActivation.text = ''
      mkdir -p '${user.home}'
      touch '${cfg.logFile}'
      chown ${toString user.uid}:${toString user.gid} '${user.home}' '${cfg.logFile}'
    '';

    system.activationScripts.postActivation.text = ''
      if ! test -f '${cfg.configFile}'; then
        echo >&2 "[1;31mwarning: ofborg config \"${cfg.configFile}\" does not exist[0m"
      fi

      chmod 600 '${cfg.configFile}'
      chown ${toString user.uid}:${toString user.gid} '${cfg.configFile}'
    '';

  };
}

