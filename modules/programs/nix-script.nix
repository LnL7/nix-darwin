{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.nix-script;

  nix-script = pkgs.substituteAll {
    inherit (cfg) name;
    src = ../../pkgs/nix-tools/nix-script.sh;
    dir = "bin";
    isExecutable = true;
  };

in

{
  options = {

    programs.nix-script.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable the nix script.
      '';
    };

    programs.nix-script.name = mkOption {
      type = types.str;
      default = "nix";
      description = ''
        Name to use for the nix script.
      '';
    };

  };

  config = mkIf cfg.enable {

    environment.systemPackages =
      [ # Nix wrapper script
        nix-script
      ];

  };
}
