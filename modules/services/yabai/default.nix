{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.yabai;

  toYabaiConfig = opts:
    concatStringsSep "\n" (mapAttrsToList
      (p: v: "yabai -m config ${p} ${toString v}") opts);

  configFile = mkIf (cfg.config != null || cfg.extraConfig != null)
    "${pkgs.writeScript "yabairc" (
      (if (cfg.config != null && cfg.config != { })
       then "${toYabaiConfig cfg.config}\n"
       else "")
      + optionalString (cfg.extraConfig != null && cfg.extraConfig != "") (cfg.extraConfig + "\n"))}";
in

{
  options = with types; {
    services.yabai.enable = mkOption {
      type = bool;
      default = false;
      description = "Whether to enable the yabai window manager.";
    };

    services.yabai.package = mkOption {
      type = path;
      default = pkgs.yabai;
      description = "The yabai package to use.";
    };

    services.yabai.enableScriptingAddition = mkOption {
      type = bool;
      default = false;
      description = ''
        Whether to enable yabai's scripting-addition.
        SIP must be (partially) disabled for this to work. See
        https://github.com/koekeishiya/yabai/wiki/Disabling-System-Integrity-Protection"

        NB: Currently, the scripting addition can only be disabled if yabai is
           _enabled_, so if you had the scripting addition enabled, you may want
            to either disable yabai over two generations, or manually run
           `sudo yabai --uninstall-sa` before disabling yabai.
      '';
    };

    services.yabai.config = mkOption {
      type = nullOr attrs;
      default = null;
      example = literalExpression ''
        {
          focus_follows_mouse = "autoraise";
          mouse_follows_focus = "off";
          window_placement    = "second_child";
          window_opacity      = "off";
          top_padding         = 36;
          bottom_padding      = 10;
          left_padding        = 10;
          right_padding       = 10;
          window_gap          = 10;
        }
      '';
      description = ''
        Key/Value pairs to pass to yabai's 'config' domain, via the configuration file.
        If both this and `services.yabai.extraConfig` are `null`, then yabai will look
        for a config file in the standard (non-Nix-managed) locations.
      '';
    };

    services.yabai.extraConfig = mkOption {
      type = nullOr str;
      default = null;
      example = literalExpression ''
        yabai -m rule --add app='System Preferences' manage=off
      '';
      description = ''
        Extra arbitrary configuration to append to the configuration file. If both this
        and `services.yabai.config` are `null`, then yabai will look for a config file
        in the standard (non-Nix-managed) locations.
      '';
    };
  };

  config = mkIf (cfg.enable) {
    environment.systemPackages = [ cfg.package ];

    launchd.user.agents.yabai = {
      serviceConfig.ProgramArguments = [ "${cfg.package}/bin/yabai" ]
                                       ++ optionals (cfg.config != null || cfg.extraConfig != null) [ "-c" configFile ];

      serviceConfig.KeepAlive = true;
      serviceConfig.RunAtLoad = true;
      serviceConfig.EnvironmentVariables = {
        PATH = "${cfg.package}/bin:${config.environment.systemPath}";
      };
    };

    launchd.daemons.yabai-sa = mkIf (cfg.enableScriptingAddition) {
      script = ''
        if [ ! $(${cfg.package}/bin/yabai --check-sa) ]; then
          ${cfg.package}/bin/yabai --install-sa \
            || ( echo >&2 "Failed to install yabai scripting addition, you may need to (partially) disable SIP." \
                 && echo >&2 "See https://github.com/koekeishiya/yabai/wiki/Disabling-System-Integrity-Protection" )
        fi

        ${cfg.package}/bin/yabai --load-sa
      '';

      serviceConfig.RunAtLoad = true;
      serviceConfig.KeepAlive.SuccessfulExit = false;
    };

    # TODO: [@cmacrae] Handle removal of yabai scripting addition when yabai is not enabled.
    system.activationScripts.yabai.text = mkIf (!cfg.enableScriptingAddition) ''
      if [ $(${cfg.package}/bin/yabai --check-sa) ]; then
        ${cfg.package}/bin/yabai --uninstall-sa
        echo >&2 "Removed yabai scripting addition, you may want to re-enable SIP."
        echo >&2 "See https://github.com/koekeishiya/yabai/wiki/Disabling-System-Integrity-Protection"
      fi
    '';

    # This is the default, but try to override it in case it’s been enabled
    # elsewhere, because yabai needs it off.
    system.defaults.spaces.spans-displays = false;
  };
}
