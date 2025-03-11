{ config, lib, ... }:

let
  cfg = config.services.openssh;
in
{
  options = {
    services.openssh.enable = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      description = ''
        Whether to enable Apple's built-in OpenSSH server.

        The default is null which means let macOS manage the OpenSSH server.
      '';
    };
  };

  config = {
    # We don't use `systemsetup -setremotelogin` as it requires Full Disk Access
    system.activationScripts.launchd.text = lib.mkIf (cfg.enable != null) (if cfg.enable then ''
      if [[ "$(systemsetup -getremotelogin | sed 's/Remote Login: //')" == "Off" ]]; then
        launchctl enable system/com.openssh.sshd
        launchctl bootstrap system /System/Library/LaunchDaemons/ssh.plist
      fi
    '' else ''
      if [[ "$(systemsetup -getremotelogin | sed 's/Remote Login: //')" == "On" ]]; then
        launchctl bootout system/com.openssh.sshd
        launchctl disable system/com.openssh.sshd
      fi
    '');
  };
}
