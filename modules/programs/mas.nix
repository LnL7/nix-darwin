{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.mas;
in
{
  options = {
    programs.mas.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable mas.";
    };

    programs.mas.applications = mkOption {
      type = types.listOf types.string;
      default = [ ];
      example = literalExample
        ''
          [ "497799835" /* Xcode */ ]
        '';
      description = "List of App Store applications for mas to install.";
    };

    programs.mas.package = mkOption {
      internal = true;
      type = types.package;
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    system.activationScripts.mas.text = ''
      echo "setting up App Store applications..."
      ${cfg.package}/bin/mas install ${lib.concatStringsSep " " cfg.applications}
    '';

  };
}
