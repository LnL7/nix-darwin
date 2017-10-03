{ config, lib, ... }:

with lib;

let

  cfg = config.system.defaults;

  boolValue = x: if x then "YES" else "NO";

  writeValue = value:
    if isBool value then "-bool ${boolValue value}" else
    if isInt value then "-int ${toString value}" else
    if isString value then "-string '${value}'" else
    throw "invalid value type";

  writeDefault = domain: key: value:
    "defaults write ${domain} '${key}' ${writeValue value}";

  defaultsToList = domain: attrs: mapAttrsToList (writeDefault domain) (filterAttrs (n: v: v != null) attrs);

  NSGlobalDomain = defaultsToList "-g" cfg.NSGlobalDomain;
  LaunchServices = defaultsToList "com.apple.LaunchServices" cfg.LaunchServices;
  dock = defaultsToList "com.apple.dock" cfg.dock;
  finder = defaultsToList "com.apple.finder" cfg.finder;
  trackpad = defaultsToList "com.apple.AppleMultitouchTrackpad" cfg.trackpad;
  trackpadBluetooth = defaultsToList "com.apple.driver.AppleBluetoothMultitouch.trackpad" cfg.trackpad;

in

{
  options = {
  };

  config = {

    system.activationScripts.defaults.text = ''
      # Set defaults
      echo "writing defaults..." >&2

      ${concatStringsSep "\n" NSGlobalDomain}
      ${concatStringsSep "\n" LaunchServices}
      ${concatStringsSep "\n" dock}
      ${concatStringsSep "\n" finder}
      ${concatStringsSep "\n" trackpad}
      ${concatStringsSep "\n" trackpadBluetooth}
    '';

  };
}
