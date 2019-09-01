{ config, pkgs, ... }:

{
  system.defaults.NSGlobalDomain.AppleFontSmoothing = 1;
  system.defaults.NSGlobalDomain.AppleKeyboardUIMode = 3;
  system.defaults.NSGlobalDomain.ApplePressAndHoldEnabled = true;
  system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;
  system.defaults.NSGlobalDomain.AppleShowScrollBars = "Always";
  system.defaults.NSGlobalDomain.NSAutomaticCapitalizationEnabled = false;
  system.defaults.NSGlobalDomain.NSAutomaticDashSubstitutionEnabled = false;
  system.defaults.NSGlobalDomain.NSAutomaticPeriodSubstitutionEnabled = false;
  system.defaults.NSGlobalDomain.NSAutomaticQuoteSubstitutionEnabled = false;
  system.defaults.NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = false;
  system.defaults.NSGlobalDomain.NSDisableAutomaticTermination = true;
  system.defaults.NSGlobalDomain.NSDocumentSaveNewDocumentsToCloud = false;
  system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode = true;
  system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode2 = true;
  system.defaults.NSGlobalDomain.NSTableViewDefaultSizeMode = 2;
  system.defaults.NSGlobalDomain.NSTextShowsControlCharacters = true;
  system.defaults.NSGlobalDomain.NSUseAnimatedFocusRing = false;
  system.defaults.NSGlobalDomain.NSScrollAnimationEnabled = true;
  system.defaults.NSGlobalDomain.NSWindowResizeTime = "0.01";
  system.defaults.NSGlobalDomain.InitialKeyRepeat = 10;
  system.defaults.NSGlobalDomain.KeyRepeat = 1;
  system.defaults.NSGlobalDomain.PMPrintingExpandedStateForPrint = true;
  system.defaults.NSGlobalDomain.PMPrintingExpandedStateForPrint2 = true;
  system.defaults.NSGlobalDomain."com.apple.keyboard.fnState" = true;
  system.defaults.NSGlobalDomain."com.apple.mouse.tapBehavior" = 1;
  system.defaults.NSGlobalDomain."com.apple.trackpad.enableSecondaryClick" = true;
  system.defaults.NSGlobalDomain."com.apple.trackpad.trackpadCornerClickBehavior" = 1;
  system.defaults.NSGlobalDomain."com.apple.springing.enabled" = true;
  system.defaults.NSGlobalDomain."com.apple.springing.delay" = "0.0";
  system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = true;
  system.defaults.".GlobalPreferences"."com.apple.sound.beep.sound" = "/System/Library/Sounds/Funk.aiff";
  system.defaults.dock.autohide-delay = "0.24";
  system.defaults.dock.orientation = "left";
  system.defaults.screencapture.location = "/tmp";
  system.defaults.smb.NetBIOSName = "IMAC-000000";
  system.defaults.smb.ServerDescription = ''Darwin\\\\U2019s iMac'';

  test = ''
    echo >&2 "checking defaults write in /activate"
    grep "defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server 'NetBIOSName' -string 'IMAC-000000'" ${config.out}/activate
    grep "defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server 'ServerDescription' -string 'Darwin.*s iMac'" ${config.out}/activate

    echo >&2 "checking defaults write in /activate-user"
    grep "defaults write -g 'AppleFontSmoothing' -int 1" ${config.out}/activate-user
    grep "defaults write -g 'AppleKeyboardUIMode' -int 3" ${config.out}/activate-user
    grep "defaults write -g 'ApplePressAndHoldEnabled' -bool YES" ${config.out}/activate-user
    grep "defaults write -g 'AppleShowAllExtensions' -bool YES" ${config.out}/activate-user
    grep "defaults write -g 'AppleShowScrollBars' -string 'Always'" ${config.out}/activate-user
    grep "defaults write -g 'NSAutomaticCapitalizationEnabled' -bool NO" ${config.out}/activate-user
    grep "defaults write -g 'NSAutomaticDashSubstitutionEnabled' -bool NO" ${config.out}/activate-user
    grep "defaults write -g 'NSAutomaticPeriodSubstitutionEnabled' -bool NO" ${config.out}/activate-user
    grep "defaults write -g 'NSAutomaticQuoteSubstitutionEnabled' -bool NO" ${config.out}/activate-user
    grep "defaults write -g 'NSAutomaticSpellingCorrectionEnabled' -bool NO" ${config.out}/activate-user
    grep "defaults write -g 'NSDisableAutomaticTermination' -bool YES" ${config.out}/activate-user
    grep "defaults write -g 'NSDocumentSaveNewDocumentsToCloud' -bool NO" ${config.out}/activate-user
    grep "defaults write -g 'NSNavPanelExpandedStateForSaveMode' -bool YES" ${config.out}/activate-user
    grep "defaults write -g 'NSNavPanelExpandedStateForSaveMode2' -bool YES" ${config.out}/activate-user
    grep "defaults write -g 'NSTableViewDefaultSizeMode' -int 2" ${config.out}/activate-user
    grep "defaults write -g 'NSTextShowsControlCharacters' -bool YES" ${config.out}/activate-user
    grep "defaults write -g 'NSUseAnimatedFocusRing' -bool NO" ${config.out}/activate-user
    grep "defaults write -g 'NSScrollAnimationEnabled' -bool YES" ${config.out}/activate-user
    grep "defaults write -g 'NSWindowResizeTime' -float 0.01" ${config.out}/activate-user
    grep "defaults write -g 'InitialKeyRepeat' -int 10" ${config.out}/activate-user
    grep "defaults write -g 'KeyRepeat' -int 1" ${config.out}/activate-user
    grep "defaults write -g 'PMPrintingExpandedStateForPrint' -bool YES" ${config.out}/activate-user
    grep "defaults write -g 'PMPrintingExpandedStateForPrint2' -bool YES" ${config.out}/activate-user
    grep "defaults write -g 'com.apple.keyboard.fnState' -bool YES" ${config.out}/activate-user
    grep "defaults write -g 'com.apple.mouse.tapBehavior' -int 1" ${config.out}/activate-user
    grep "defaults write -g 'com.apple.trackpad.enableSecondaryClick' -bool YES" ${config.out}/activate-user
    grep "defaults write -g 'com.apple.trackpad.trackpadCornerClickBehavior' -int 1" ${config.out}/activate-user
    grep "defaults write -g 'com.apple.springing.enabled' -bool YES" ${config.out}/activate-user
    grep "defaults write -g 'com.apple.springing.delay' -float 0.0" ${config.out}/activate-user
    grep "defaults write -g 'com.apple.swipescrolldirection' -bool YES" ${config.out}/activate-user
    grep "defaults write .GlobalPreferences 'com.apple.sound.beep.sound' -string '/System/Library/Sounds/Funk.aiff'" ${config.out}/activate-user
    grep "defaults write com.apple.dock 'autohide-delay' -float 0.24" ${config.out}/activate-user
    grep "defaults write com.apple.dock 'orientation' -string 'left'" ${config.out}/activate-user
    grep "defaults write com.apple.screencapture 'location' -string '/tmp'" ${config.out}/activate-user
  '';
}
