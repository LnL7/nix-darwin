{ config, lib, ... }:

with lib;

let
  cfg = config.security.sudo;
in
{
  meta.maintainers = [
    lib.maintainers.samasaur or "samasaur"
  ];

  options = {
    security.sudo.extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = mdDoc ''
        Extra configuration text appended to {file}`sudoers`.
      '';
    };
  };

  config = {
    environment.etc."sudoers.d/10-nix-darwin-extra-config".text = lib.mkIf (cfg.extraConfig != "") cfg.extraConfig;
  };
}
