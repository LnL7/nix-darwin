{ config, lib, ... }:

with lib;

let
  cfg = config.system.defaults;

  isFloat = x: isString x && builtins.match "^[+-]?([0-9]*[.])?[0-9]+$" x != null;

  boolValue = x: if x then "YES" else "NO";

  writeValue = value:
    if isBool value then "-bool ${boolValue value}" else
    if isInt value then "-int ${toString value}" else
    if isFloat value then "-float ${toString value}" else
    if isString value then "-string '${value}'" else
    throw "invalid value type";

  writeDefault = domain: key: value:
    "defaults write ${domain} '${key}' ${writeValue value}";

  defaultsToList = domain: attrs: mapAttrsToList (writeDefault domain) (filterAttrs (n: v: v != null) attrs);

  NSGlobalDomain = defaultsToList "-g" cfg.NSGlobalDomain;
  GlobalPreferences = defaultsToList ".GlobalPreferences" cfg.".GlobalPreferences";
  LaunchServices = defaultsToList "com.apple.LaunchServices" cfg.LaunchServices;
  dock = defaultsToList "com.apple.dock" cfg.dock;
  finder = defaultsToList "com.apple.finder" cfg.finder;
  smb = defaultsToList "/Library/Preferences/SystemConfiguration/com.apple.smb.server" cfg.smb;
  screencapture = defaultsToList "com.apple.screencapture" cfg.screencapture;
  trackpad = defaultsToList "com.apple.AppleMultitouchTrackpad" cfg.trackpad;
  trackpadBluetooth = defaultsToList "com.apple.driver.AppleBluetoothMultitouch.trackpad" cfg.trackpad;

  mkIfAttrs = list: mkIf (any (attrs: attrs != {}) list);
in

{
  config = {

    system.activationScripts.defaults.text = mkIfAttrs [ smb ]
      ''
        # Set defaults
        echo >&2 "system defaults..."
        ${concatStringsSep "\n" smb}
      '';

    system.activationScripts.userDefaults.text = mkIfAttrs
      [ NSGlobalDomain GlobalPreferences LaunchServices dock finder screencapture trackpad trackpadBluetooth ]
      ''
        # Set defaults
        echo >&2 "user defaults..."

        ${concatStringsSep "\n" NSGlobalDomain}
        ${concatStringsSep "\n" GlobalPreferences}
        ${concatStringsSep "\n" LaunchServices}
        ${concatStringsSep "\n" dock}
        ${concatStringsSep "\n" finder}
        ${concatStringsSep "\n" screencapture}
        ${concatStringsSep "\n" trackpad}
        ${concatStringsSep "\n" trackpadBluetooth}
      '';

  };
}
