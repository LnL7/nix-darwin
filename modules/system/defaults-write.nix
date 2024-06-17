{ config, lib, ... }:

with lib;

let
  cfg = config.system.defaults;

  writeDefault = domain: key: value:
    "defaults write ${domain} '${key}' $'${strings.escape [ "'" ] (generators.toPlist { } value)}'";

  defaultsToList = domain: attrs: mapAttrsToList (writeDefault domain) (filterAttrs (n: v: v != null) attrs);

  configurableUsers = lib.filterAttrs (n: v: lib.hasPrefix "/Users" v.home) config.users.users;
  userDefaultsToList = domain: attrs: builtins.concatLists (mapAttrsToList (n: v:
    (builtins.map (cmd: "sudo -u ${n} " + cmd) (defaultsToList "${v.home}/Library/Preferences/${domain}" attrs))
  ) configurableUsers);

  # defaults
  alf = defaultsToList "/Library/Preferences/com.apple.alf" cfg.alf;
  loginwindow = defaultsToList "/Library/Preferences/com.apple.loginwindow" cfg.loginwindow;
  smb = defaultsToList "/Library/Preferences/SystemConfiguration/com.apple.smb.server" cfg.smb;
  SoftwareUpdate = defaultsToList "/Library/Preferences/SystemConfiguration/com.apple.SoftwareUpdate" cfg.SoftwareUpdate;

  # userDefaults
  GlobalPreferences = userDefaultsToList ".GlobalPreferences" cfg.".GlobalPreferences";
  LaunchServices = userDefaultsToList "com.apple.LaunchServices" cfg.LaunchServices;
  NSGlobalDomain = userDefaultsToList ".GlobalPreferences" cfg.NSGlobalDomain;
  menuExtraClock = userDefaultsToList "com.apple.menuextra.clock" cfg.menuExtraClock;
  dock = userDefaultsToList "com.apple.dock" cfg.dock;
  finder = userDefaultsToList "com.apple.finder" cfg.finder;
  magicmouse = userDefaultsToList "com.apple.AppleMultitouchMouse" cfg.magicmouse;
  magicmouseBluetooth = userDefaultsToList "com.apple.driver.AppleMultitouchMouse.mouse" cfg.magicmouse;
  screencapture = userDefaultsToList "com.apple.screencapture" cfg.screencapture;
  screensaver = userDefaultsToList "com.apple.screensaver" cfg.screensaver;
  spaces = userDefaultsToList "com.apple.spaces" cfg.spaces;
  trackpad = userDefaultsToList "com.apple.AppleMultitouchTrackpad" cfg.trackpad;
  trackpadBluetooth = userDefaultsToList "com.apple.driver.AppleBluetoothMultitouch.trackpad" cfg.trackpad;
  universalaccess = userDefaultsToList "com.apple.universalaccess" cfg.universalaccess;
  ActivityMonitor = userDefaultsToList "com.apple.ActivityMonitor" cfg.ActivityMonitor;
  CustomUserPreferences = flatten (mapAttrsToList (name: value: userDefaultsToList name value) cfg.CustomUserPreferences);
  CustomSystemPreferences = flatten (mapAttrsToList (name: value: userDefaultsToList name value) cfg.CustomSystemPreferences);

  mkIfAttrs = list: mkIf (any (attrs: attrs != { }) list);
in

{
  config = {

    # Type used for `system.defaults.<domain>.*` options that previously accepted float values as a
    # string.
    lib.defaults.types.floatWithDeprecationError = types.float // {
      check = x:
        if isString x && builtins.match "^[+-]?([0-9]*[.])?[0-9]+$" x != null
        then throw "Using strings for `system.defaults.<domain>.*' options of type float is no longer permitted, use native float values instead."
        else types.float.check x;
    };

    system.activationScripts.defaults.text = mkIfAttrs [
      alf
      loginwindow
      smb
      SoftwareUpdate
      CustomSystemPreferences
    ]
      ''
        # Set defaults
        echo >&2 "system defaults..."
        ${concatStringsSep "\n" alf}
        ${concatStringsSep "\n" loginwindow}
        ${concatStringsSep "\n" smb}
        ${concatStringsSep "\n" SoftwareUpdate}
        ${concatStringsSep "\n" CustomSystemPreferences}
      '';

    system.activationScripts.userDefaults.text = mkIfAttrs
      [
        GlobalPreferences
        LaunchServices
        NSGlobalDomain
        menuExtraClock
        dock
        finder
        magicmouse
        magicmouseBluetooth
        screencapture
        screensaver
        spaces
        trackpad
        trackpadBluetooth
        universalaccess
        ActivityMonitor
        CustomUserPreferences
      ]
      ''
        # Set defaults
        echo >&2 "user defaults..."

        ${concatStringsSep "\n" NSGlobalDomain}

        ${concatStringsSep "\n" GlobalPreferences}
        ${concatStringsSep "\n" LaunchServices}
        ${concatStringsSep "\n" menuExtraClock}
        ${concatStringsSep "\n" dock}
        ${concatStringsSep "\n" finder}
        ${concatStringsSep "\n" magicmouse}
        ${concatStringsSep "\n" magicmouseBluetooth}
        ${concatStringsSep "\n" screencapture}
        ${concatStringsSep "\n" screensaver}
        ${concatStringsSep "\n" spaces}
        ${concatStringsSep "\n" trackpad}
        ${concatStringsSep "\n" trackpadBluetooth}
        ${concatStringsSep "\n" universalaccess}
        ${concatStringsSep "\n" ActivityMonitor}
        ${concatStringsSep "\n" CustomUserPreferences}

        ${optionalString (length dock > 0) ''
          echo >&2 "restarting Dock..."
          killall Dock
        ''}
      '';

  };
}
