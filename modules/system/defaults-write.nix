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
  desktopservices = defaultsToList "com.apple.desktopservices" cfg.desktopservices;
  dock = defaultsToList "com.apple.dock" cfg.dock;
  finder = defaultsToList "com.apple.finder" cfg.finder;
  alf = defaultsToList "/Library/Preferences/com.apple.alf" cfg.alf;
  loginwindow = defaultsToList "/Library/Preferences/com.apple.loginwindow" cfg.loginwindow;
  smb = defaultsToList "/Library/Preferences/SystemConfiguration/com.apple.smb.server" cfg.smb;
  SoftwareUpdate = defaultsToList "/Library/Preferences/SystemConfiguration/com.apple.SoftwareUpdate" cfg.SoftwareUpdate;
  screencapture = defaultsToList "com.apple.screencapture" cfg.screencapture;
  spaces = defaultsToList "com.apple.spaces" cfg.spaces;
  textedit = defaultsToList "com.apple.TextEdit" cfg.textedit;
  trackpad = defaultsToList "com.apple.AppleMultitouchTrackpad" cfg.trackpad;
  trackpadBluetooth = defaultsToList "com.apple.driver.AppleBluetoothMultitouch.trackpad" cfg.trackpad;

  mkIfAttrs = list: mkIf (any (attrs: attrs != {}) list);
in

{
  config = {

    system.activationScripts.defaults.text = mkIfAttrs [ alf loginwindow smb SoftwareUpdate ]
      ''
        # Set defaults
        echo >&2 "system defaults..."
        ${concatStringsSep "\n" alf}
        ${concatStringsSep "\n" loginwindow}
        ${concatStringsSep "\n" smb}
        ${concatStringsSep "\n" SoftwareUpdate}
      '';

    system.activationScripts.userDefaults.text = mkIfAttrs
      [ NSGlobalDomain GlobalPreferences LaunchServices desktopservices dock finder screencapture spaces trackpad trackpadBluetooth ]
      ''
        # Set defaults
        echo >&2 "user defaults..."

        ${concatStringsSep "\n" NSGlobalDomain}
        ${concatStringsSep "\n" GlobalPreferences}
        ${concatStringsSep "\n" LaunchServices}
        ${concatStringsSep "\n" desktopservices}
        ${concatStringsSep "\n" dock}
        ${concatStringsSep "\n" finder}
        ${concatStringsSep "\n" screencapture}
        ${concatStringsSep "\n" spaces}
        ${concatStringsSep "\n" textedit}
        ${concatStringsSep "\n" trackpad}
        ${concatStringsSep "\n" trackpadBluetooth}
      '';

  };
}
