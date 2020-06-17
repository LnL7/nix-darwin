{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.zsh;

  zshVariables =
    mapAttrsToList (n: v: ''${n}="${v}"'') cfg.variables;

  fzfCompletion = ./fzf-completion.zsh;
  fzfGit = ./fzf-git.zsh;
  fzfHistory = ./fzf-history.zsh;
in

{
  options = {
    programs.zsh.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to configure zsh as an interactive shell.";
    };

    programs.zsh.variables = mkOption {
      type = types.attrsOf (types.either types.str (types.listOf types.str));
      default = {};
      description = ''
        A set of environment variables used in the global environment.
        These variables will be set on shell initialisation.
        The value of each variable can be either a string or a list of
        strings.  The latter is concatenated, interspersed with colon
        characters.
      '';
      apply = mapAttrs (n: v: if isList v then concatStringsSep ":" v else v);
    };

    programs.zsh.shellInit = mkOption {
      type = types.lines;
      default = "";
      description = "Shell script code called during zsh shell initialisation.";
    };

    programs.zsh.loginShellInit = mkOption {
      type = types.lines;
      default = "";
      description = "Shell script code called during zsh login shell initialisation.";
    };

    programs.zsh.interactiveShellInit = mkOption {
      type = types.lines;
      default = "";
      description = "Shell script code called during interactive zsh shell initialisation.";
    };

    programs.zsh.promptInit = mkOption {
      type = types.lines;
      default = "autoload -U promptinit && promptinit && prompt walters";
      description = "Shell script code used to initialise the zsh prompt.";
    };

    programs.zsh.enableCompletion = mkOption {
      type = types.bool;
      default = true;
      description = "Enable zsh completion for all interactive zsh shells.";
    };

    programs.zsh.enableBashCompletion = mkOption {
      type = types.bool;
      default = true;
      description = "Enable bash completion for all interactive zsh shells.";
    };

    programs.zsh.enableFzfCompletion = mkOption {
      type = types.bool;
      default = false;
      description = "Enable fzf completion.";
    };

    programs.zsh.enableFzfGit = mkOption {
      type = types.bool;
      default = false;
      description = "Enable fzf keybindings for C-g git browsing.";
    };

    programs.zsh.enableFzfHistory = mkOption {
      type = types.bool;
      default = false;
      description = "Enable fzf keybinding for Ctrl-r history search.";
    };

    programs.zsh.enableSyntaxHighlighting = mkOption {
      type = types.bool;
      default = false;
      description = "Enable zsh-syntax-highlighting.";
    };
  };

  config = mkIf cfg.enable {

    environment.systemPackages =
      [ # Include zsh package
        pkgs.zsh
      ] ++ optional cfg.enableCompletion pkgs.nix-zsh-completions
        ++ optional cfg.enableSyntaxHighlighting pkgs.zsh-syntax-highlighting;

    environment.pathsToLink = [ "/share/zsh" ];

    environment.loginShell = "zsh -l";
    environment.variables.SHELL = "${pkgs.zsh}/bin/zsh";

    environment.etc."zshenv".text = ''
      # /etc/zshenv: DO NOT EDIT -- this file has been generated automatically.
      # This file is read for all shells.

      # Only execute this file once per shell.
      # But don't clobber the environment of interactive non-login children!
      if [ -n "$__ETC_ZSHENV_SOURCED" ]; then return; fi
      export __ETC_ZSHENV_SOURCED=1

      # Don't execute this file when running in a pure nix-shell.
      if test -n "$IN_NIX_SHELL"; then return; fi

      if [ -z "$__NIX_DARWIN_SET_ENVIRONMENT_DONE" ]; then
        . ${config.system.build.setEnvironment}
      fi

      ${cfg.shellInit}

      # Read system-wide modifications.
      if test -f /etc/zshenv.local; then
        source /etc/zshenv.local
      fi
    '';

    environment.etc."zprofile".text = ''
      # /etc/zprofile: DO NOT EDIT -- this file has been generated automatically.
      # This file is read for login shells.

      # Only execute this file once per shell.
      if [ -n "$__ETC_ZPROFILE_SOURCED" ]; then return; fi
      __ETC_ZPROFILE_SOURCED=1

      ${concatStringsSep "\n" zshVariables}
      ${config.system.build.setAliases.text}

      ${cfg.loginShellInit}

      # Read system-wide modifications.
      if test -f /etc/zprofile.local; then
        source /etc/zprofile.local
      fi
    '';

    environment.etc."zshrc".text = ''
      # /etc/zshrc: DO NOT EDIT -- this file has been generated automatically.
      # This file is read for interactive shells.

      # Only execute this file once per shell.
      if [ -n "$__ETC_ZSHRC_SOURCED" -o -n "$NOSYSZSHRC" ]; then return; fi
      __ETC_ZSHRC_SOURCED=1

      # history defaults
      SAVEHIST=2000
      HISTSIZE=2000
      HISTFILE=$HOME/.zsh_history

      setopt HIST_IGNORE_DUPS SHARE_HISTORY HIST_FCNTL_LOCK

      bindkey -e

      ${config.environment.interactiveShellInit}
      ${cfg.interactiveShellInit}

      # Tell zsh how to find installed completions
      for p in ''${(z)NIX_PROFILES}; do
        fpath+=($p/share/zsh/site-functions $p/share/zsh/$ZSH_VERSION/functions $p/share/zsh/vendor-completions)
      done

      ${cfg.promptInit}

      ${optionalString cfg.enableCompletion "autoload -U compinit && compinit"}
      ${optionalString cfg.enableBashCompletion "autoload -U bashcompinit && bashcompinit"}

      ${optionalString cfg.enableSyntaxHighlighting
        "source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
      }

      ${optionalString cfg.enableFzfCompletion "source ${fzfCompletion}"}
      ${optionalString cfg.enableFzfGit "source ${fzfGit}"}
      ${optionalString cfg.enableFzfHistory "source ${fzfHistory}"}

      # Read system-wide modifications.
      if test -f /etc/zshrc.local; then
        source /etc/zshrc.local
      fi
    '';

    environment.etc."zprofile".knownSha256Hashes = [
      "db8422f92d8cff684e418f2dcffbb98c10fe544b5e8cd588b2009c7fa89559c5"
      "0235d3c1b6cf21e7043fbc98e239ee4bc648048aafaf6be1a94a576300584ef2"
    ];

    environment.etc."zshrc".knownSha256Hashes = [
      "19a2d673ffd47b8bed71c5218ff6617dfc5e8533b240b9ba79142a45f8823c23"
      "fb5827cb4712b7e7932d438067ec4852c8955a9ff0f55e282473684623ebdfa1"
      "c5a00c072c920f46216454978c44df044b2ec6d03409dc492c7bdcd92c94a110"  # nix install
      "40b0d8751adae5b0100a4f863be5b75613a49f62706427e92604f7e04d2e2261"  # nix install
    ];

  };
}
