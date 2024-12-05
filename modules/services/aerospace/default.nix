{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.aerospace;

  format = pkgs.formats.toml { };
  configFile = format.generate "aerospace.toml" cfg.settings;
in

{
  options = {
    services.aerospace = with lib.types; {
      enable = lib.mkEnableOption "AeroSpace window manager";

      package = lib.mkPackageOption pkgs "aerospace" { };

      settings = lib.mkOption {
        type = submodule {
          freeformType = format.type;
          options = {
            start-at-login = lib.mkOption {
              type = bool;
              default = false;
              description = "Do not start AeroSpace at login. (Managed by launchd instead)";
            };
            after-login-command = lib.mkOption {
              type = listOf str;
              default = [ ];
              description = "Do not use AeroSpace to run commands after login. (Managed by launchd instead)";
            };
            after-startup-command = lib.mkOption {
              type = listOf str;
              default = [ ];
              description = "Add commands that run after AeroSpace startup";
              example = [ "layout tiles" ];
            };
            enable-normalization-flatten-containers = lib.mkOption {
              type = bool;
              default = true;
              description = "Containers that have only one child are \"flattened\".";
            };
            enable-normalization-opposite-orientation-for-nested-containers = lib.mkOption {
              type = bool;
              default = true;
              description = "Containers that nest into each other must have opposite orientations.";
            };
            accordion-padding = lib.mkOption {
              type = int;
              default = 30;
              description = "Padding between windows in an accordion container.";
            };
            default-root-container-layout = lib.mkOption {
              type = enum [
                "tiles"
                "accordion"
              ];
              default = "tiles";
              description = "Default layout for the root container.";
            };
            default-root-container-orientation = lib.mkOption {
              type = enum [
                "horizontal"
                "vertical"
                "auto"
              ];
              default = "auto";
              description = "Default orientation for the root container.";
            };
            on-window-detected = lib.mkOption {
              type = listOf str;
              default = [ ];
              description = "Commands to run every time a new window is detected.";
            };
            on-focus-changed = lib.mkOption {
              type = listOf str;
              default = [ ];
              description = "Commands to run every time focused window or workspace changes.";
            };
            on-focused-monitor-changed = lib.mkOption {
              type = listOf str;
              default = [ "move-mouse monitor-lazy-center" ];
              description = "Commands to run every time focused monitor changes.";
            };
            exec-on-workspace-change = lib.mkOption {
              type = listOf str;
              default = [ ];
              example = [
                "/bin/bash"
                "-c"
                "sketchybar --trigger aerospace_workspace_change FOCUSED=$AEROSPACE_FOCUSED_WORKSPACE"
              ];
              description = "Commands to run every time workspace changes.";
            };
            key-mapping.preset = lib.mkOption {
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
        example = lib.literalExpression ''
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

  config = (
    lib.mkIf (cfg.enable) {
      assertions = [
        {
          assertion = !cfg.settings.start-at-login;
          message = "AeroSpace started at login is managed by home-manager and launchd instead of itself via this option.";
        }
        {
          assertion = cfg.settings.after-login-command == [ ];
          message = "AeroSpace will not run these commands as it does not start itself.";
        }
      ];
      environment.systemPackages = [ cfg.package ];

      launchd.user.agents.aerospace = {
        command =
          "${cfg.package}/Applications/AeroSpace.app/Contents/MacOS/AeroSpace"
          + (lib.optionalString (cfg.settings != { }) " --config-path ${configFile}");
        serviceConfig = {
          KeepAlive = true;
          RunAtLoad = true;
        };
      };
    }
  );
}
