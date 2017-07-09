{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.bash;

  shell = pkgs.runCommand pkgs.bashInteractive.name
    { buildInputs = [ pkgs.makeWrapper ]; }
    ''
      source $stdenv/setup

      mkdir -p $out/bin
      makeWrapper ${pkgs.bashInteractive}/bin/bash $out/bin/bash
    '';

in

{
  options = {

    programs.bash.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to configure bash as an interactive shell.";
    };

    programs.bash.interactiveShellInit = mkOption {
      default = "";
      description = "Shell script code called during interactive bash shell initialisation.";
      type = types.lines;
    };

    programs.bash.enableCompletion = mkOption {
      type = types.bool;
      default = true;
      description = "Enable bash completion for all interactive bash shells.";
    };

  };

  config = mkIf cfg.enable {

    environment.systemPackages =
      [ # Include bash package
        pkgs.bashInteractive
      ] ++ optional cfg.enableCompletion pkgs.bash-completion;

    environment.pathsToLink =
      [ "/etc/bash_completion.d"
        "/share/bash-completion/completions"
      ];

    environment.loginShell = mkDefault "${shell}/bin/bash -l";
    environment.variables.SHELL = mkDefault "${shell}/bin/bash";

    environment.etc."bashrc".text = ''
      # /etc/bashrc: DO NOT EDIT -- this file has been generated automatically.
      # This file is read for interactive shells.

      if [ -z "$PS1" ]; then return; fi

      PS1='\h:\W \u\$ '
      # Make bash check its window size after a process completes
      shopt -s checkwinsize

      [ -r "/etc/bashrc_$TERM_PROGRAM" ] && . "/etc/bashrc_$TERM_PROGRAM"

      # Only execute this file once per shell.
      if [ -n "$__ETC_BASHRC_SOURCED" -o -n "$NOSYSBASHRC" ]; then return; fi
      __ETC_BASHRC_SOURCED=1

      export PATH=${config.environment.systemPath}
      ${config.system.build.setEnvironment}
      ${config.system.build.setAliases}

      ${config.environment.extraInit}
      ${config.environment.interactiveShellInit}
      ${cfg.interactiveShellInit}

      ${optionalString cfg.enableCompletion ''
        source "${pkgs.bash-completion}/etc/profile.d/bash_completion.sh"

        nullglobStatus=$(shopt -p nullglob)
        shopt -s nullglob
        for p in $NIX_PROFILES; do
          for m in "$p/etc/bash_completion.d/"* "$p/share/bash-completion/completions/"*; do
            source $m
          done
        done
        eval "$nullglobStatus"
        unset nullglobStatus p m
      ''}

      # Read system-wide modifications.
      if test -f /etc/bash.local; then
        source /etc/bash.local
      fi
    '';

  };
}
