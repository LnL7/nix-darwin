{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.zsh;

  zsh = pkgs.runCommand pkgs.zsh.name
    { buildInputs = [ pkgs.makeWrapper ]; }
    ''
      source $stdenv/setup

      mkdir -p $out/bin
      makeWrapper ${pkgs.zsh}/bin/zsh $out/bin/zsh
    '';

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
      default = "${zsh}/bin/zsh";
      description = ''
        Zsh shell to use.
      '';
    };

    programs.zsh.shellInit = mkOption {
      default = "";
      description = ''
        Shell script code called during zsh shell initialisation.
      '';
      type = types.lines;
    };

    programs.zsh.loginShellInit = mkOption {
      default = "";
      description = ''
        Shell script code called during zsh login shell initialisation.
      '';
      type = types.lines;
    };

    programs.zsh.interactiveShellInit = mkOption {
      default = "";
      description = ''
        Shell script code called during interactive zsh shell initialisation.
      '';
      type = types.lines;
    };

  };

  config = mkIf cfg.enable {

    environment.systemPackages =
      [ # Include zsh package
        pkgs.zsh
      ];

    environment.variables.SHELL = "${cfg.shell}";

    environment.etc."zshenv".text = ''
      # /etc/zshenv: DO NOT EDIT -- this file has been generated automatically.
      # This file is read for all shells.

      # Only execute this file once per shell.
      # But don't clobber the environment of interactive non-login children!
      if [ -n "$__ETC_ZSHENV_SOURCED" ]; then return; fi
      export __ETC_ZSHENV_SOURCED=1

      ${cfg.shellInit}

      # Read system-wide modifications.
      if test -f /etc/zshenv.local; then
        . /etc/zshenv.local
      fi
    '';

    environment.etc."zprofile".text = ''
      # /etc/zprofile: DO NOT EDIT -- this file has been generated automatically.
      # This file is read for login shells.

      # Only execute this file once per shell.
      if [ -n "$__ETC_ZPROFILE_SOURCED" ]; then return; fi
      __ETC_ZPROFILE_SOURCED=1

      ${cfg.loginShellInit}

      # Read system-wide modifications.
      if test -f /etc/zprofile.local; then
        . /etc/zprofile.local
      fi
    '';

    environment.etc."zshrc".text = ''
      # /etc/zshrc: DO NOT EDIT -- this file has been generated automatically.
      # This file is read for interactive shells.

      # Only execute this file once per shell.
      if [ -n "$__ETC_ZSHRC_SOURCED" -o -n "$NOSYSZSHRC" ]; then return; fi
      __ETC_ZSHRC_SOURCED=1

      export PATH=${config.environment.systemPath}''${PATH:+:$PATH}
      ${config.system.build.setEnvironment}
      ${config.system.build.setAliases}

      ${cfg.interactiveShellInit}

      # Read system-wide modifications.
      if test -f /etc/zshrc.local; then
        . /etc/zshrc.local
      fi
    '';

  };
}
