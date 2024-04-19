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
      type = types.nullOr types.lines;
      default = null;
      description = ''
        Extra configuration text appended to {file}`sudoers`.
      '';
    };
  };

  config = {
    environment.etc = {
      "sudoers.d/10-nix-darwin-extra-config" = mkIf (cfg.extraConfig != null) {
        text = cfg.extraConfig;
      };
    };
  };
}
