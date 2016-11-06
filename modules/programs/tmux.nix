{ config, lib, pkgs, ... }:

with lib;

let

  inherit (pkgs) stdenv;

  cfg = config.programs.tmux;

  tmuxConfigs =
    mapAttrsToList (n: v: "${v}") cfg.text;

in {
  options = {

    programs.tmux.loginShell = mkOption {
      type = types.path;
      default = "$SHELL";
      description = ''
        Configure default login shell.
      '';
    };

    programs.tmux.enableSensible = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Enable sensible configuration options.
      '';
    };

    programs.tmux.enableMouse = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Enable mouse support.
      '';
    };

    programs.tmux.enableVim = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Enable vim style keybindings for copy mode, and navigation of panes.
      '';
    };

    programs.tmux.config = mkOption {
      type = types.lines;
      description = ''
        Configuration options.
      '';
    };

    programs.tmux.text = mkOption {
      internal = true;
      type = types.attrsOf types.lines;
      default = {};
    };

  };

  config = {

    programs.tmux.config = concatStringsSep "\n" tmuxConfigs;

    programs.tmux.text.login-shell = if stdenv.isDarwin then ''
      set -g default-command "reattach-to-user-namespace ${cfg.loginShell}"
    '' else ''
      set -g default-command "${cfg.loginShell}"
    '';

    programs.tmux.text.sensible = mkIf cfg.enableSensible (''
      set -g default-terminal "screen-256color"
      setw -g aggressive-resize on

      set -g base-index 1
      set -g renumber-windows on

      set -g status-keys emacs
      set -s escape-time 0

      bind c new-window -c '#{pane_current_path}'
      bind % split-window -v -c '#{pane_current_path}'
      bind '"' split-window -h -c '#{pane_current_path}'

      # TODO: make these interactive
      bind C new-session
      bind S switch-client -l

      # set -g status-utf8 on
      # set -g utf8 on
    '');

    programs.tmux.text.mouse = mkIf cfg.enableMouse ''
      set -g mouse on
      setw -g mouse on
      set -g terminal-overrides 'xterm*:smcup@:rmcup@'
    '';

    programs.tmux.text.vim = mkIf cfg.enableVim (''
      setw -g mode-keys vi

      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      bind s split-window -v -c '#{pane_current_path}'
      bind v split-window -h -c '#{pane_current_path}'

      bind -t vi-copy v begin-selection
    '' + optionalString stdenv.isLinux ''
      bind -t vi-copy y copy-selection
    '' + optionalString stdenv.isDarwin ''
      bind -t vi-copy y copy-pipe "reattach-to-user-namespace pbcopy"
    '');

  };
}
