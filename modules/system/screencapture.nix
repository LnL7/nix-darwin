{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.system.screencapture;
  screenshotsLocation = config.system.defaults.screencapture.location;
in
{
  options.system.screencapture = {
    createLocation = mkOption {
      type = types.bool;
      default = false;
      description = "Create the screencapture location if set.";
    };
  };

  config = {
    system.activationScripts.screencapture.text = mkIf (cfg.createLocation && screenshotsLocation != null) ''
      if [ ! -d "${screenshotsLocation}" ]; then
        echo "creating screenshots directory..."
        mkdir -pv "${screenshotsLocation}"
      fi
    '';
  };
}
