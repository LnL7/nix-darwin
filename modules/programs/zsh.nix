{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.zsh;

in

{
  options = {

    programs.zsh.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to configure zsh as an interactive shell.
      '';
    };

    programs.zsh.shell = mkOption {
      type = types.path;
      default = "${pkgs.zsh}/bin/zsh";
      description = ''
        Zsh shell to use.
      '';
    };

  };

  config = mkIf cfg.enable {

    environment.variables.SHELL = "${cfg.shell}";

  };
}
