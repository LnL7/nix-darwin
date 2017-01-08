{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.bash;

  shell = pkgs.runCommand pkgs.zsh.name
    { buildInputs = [ pkgs.makeWrapper ]; }
    ''
      source $stdenv/setup

      mkdir -p $out/bin
      makeWrapper ${pkgs.bash}/bin/bash $out/bin/bash
    '';

in

{
  options = {

    programs.bash.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to configure bash as an interactive shell.
      '';
    };

    programs.bash.interactiveShellInit = mkOption {
      default = "";
      description = ''
        Shell script code called during interactive bash shell initialisation.
      '';
      type = types.lines;
    };

  };

  config = mkIf cfg.enable {

    environment.systemPackages =
      [ # Include bash package
        pkgs.bash
      ];

    environment.loginShell = mkDefault "${shell}/bin/bash -l";
    environment.variables.SHELL = mkDefault "${shell}/bin/bash";

    environment.etc."bashrc".text = ''
      # /etc/bashrc: DO NOT EDIT -- this file has been generated automatically.
      # This file is read for interactive shells.

      # Only execute this file once per shell.
      if [ -n "$__ETC_BASHRC_SOURCED" -o -n "$NOSYSBASHRC" ]; then return; fi
      __ETC_BASHRC_SOURCED=1

      export PATH=${config.environment.systemPath}''${PATH:+:$PATH}
      ${config.system.build.setEnvironment}
      ${config.system.build.setAliases}

      ${config.environment.extraInit}
      ${config.environment.interactiveShellInit}
      ${cfg.interactiveShellInit}

      # Read system-wide modifications.
      if test -f /etc/bash.local; then
        . /etc/bash.local
      fi
    '';

  };
}
