{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.aerospace;

  format = pkgs.formats.toml { };
  configFile = format.generate "aerospace.toml" cfg.settings;
in

{
  options = with types; {
    services.aerospace = {
      enable = mkEnableOption "AeroSpace window manager";

      package = mkOption {
        type = types.path;
        default = pkgs.aerospace;
        description = "The AeroSpace package to use.";
      };

      settings = mkOption {
        type = submodule {
          freeformType = format.type;
          options = {
            start-at-login = mkOption {
              type = addCheck bool (b: !false || !cfg.enable);
              default = false;
              description = "Do not start AeroSpace at login. (Managed by launchd instead)";
            };
            after-login-command = mkOption {
              type = addCheck (listOf str) (l: l == [ ] || !cfg.enable);
              default = [ ];
              description = "Do not use AeroSpace to run commands after login. (Managed by launchd instead)";
            };
            after-startup-command = mkOption {
              type = addCheck (listOf str) (l: l == [ ] || !cfg.enable);
              default = [ ];
              description = "Do not use AeroSpace to run commands after startup. (Managed by launchd instead)";
            };
            enable-normalization-flatten-containers = mkOption {
              type = bool;
              default = true;
              description = "Containers that have only one child are \"flattened\".";
            };
            enable-normalization-opposite-orientation-for-nested-containers = mkOption {
              type = bool;
              default = true;
              description = "Containers that nest into each other must have opposite orientations.";
            };
            accordion-padding = mkOption {
              type = int;
              default = 30;
              description = "Padding between windows in an accordion container.";
            };
            default-root-container-layout = mkOption {
              type = enum [
                "tiles"
                "accordion"
              ];
              default = "tiles";
              description = "Default layout for the root container.";
            };
            default-root-container-orientation = mkOption {
              type = enum [
                "horizontal"
                "vertical"
                "auto"
              ];
              default = "auto";
              description = "Default orientation for the root container.";
            };
            on-window-detected = mkOption {
              type = listOf str;
              default = [ ];
              description = "Commands to run every time a new window is detected.";
            };
            on-focus-changed = mkOption {
              type = listOf str;
              default = [ ];
              description = "Commands to run every time focused window or workspace changes.";
            };
            on-focused-monitor-changed = mkOption {
              type = listOf str;
              default = [ "move-mouse monitor-lazy-center" ];
              description = "Commands to run every time focused monitor changes.";
            };
            exec-on-workspace-change = mkOption {
              type = listOf str;
              default = [ ];
              example = [
                "/bin/bash"
                "-c"
                "sketchybar --trigger aerospace_workspace_change FOCUSED=$AEROSPACE_FOCUSED_WORKSPACE"
              ];
              description = "Commands to run every time workspace changes.";
            };
            key-mapping.preset = mkOption {
              type = enum [
                "qwerty"
                "dvorak"
              ];
              default = "qwerty";
              description = "Keymapping preset.";
            };
          };
        };
        default = { };
        example = literalExpression ''
          {
            gaps = {
              outer.left = 8;
              outer.bottom = 8;
              outer.top = 8;
              outer.right = 8;
            };
            mode.main.binding = {
              alt-h = "focus left";
              alt-j = "focus down";
              alt-k = "focus up";
              alt-l = "focus right";
            };
          }
        '';
        description = ''
          AeroSpace configuration, see
          <link xlink:href="https://nikitabobko.github.io/AeroSpace/guide#configuring-aerospace"/>
          for supported values.
        '';
      };
    };
  };

  config = mkMerge [
    (mkIf (cfg.enable) {
      environment.systemPackages = [ cfg.package ];

      launchd.user.agents.aerospace.serviceConfig = {
        ProgramArguments =
          [ "${cfg.package}/Applications/AeroSpace.app/Contents/MacOS/AeroSpace" ]
          ++ optionals (cfg.settings != { }) [
            "--config-path"
            "${configFile}"
          ];
        KeepAlive = true;
        RunAtLoad = true;
      };
    })
  ];
}
