{ config, lib, pkgs, ... }:

with lib;

{
  # We are uninstalling, disable sanity checks.
  assertions = mkForce [];
  system.activationScripts.checks.text = mkForce "";

  # Disable etc, launchd, ...
  environment.etc = mkForce {};
  launchd.agents = mkForce {};
  launchd.daemons = mkForce {};
  launchd.user.agents = mkForce {};

  system.activationScripts.postUserActivation.text = mkAfter ''
    if test -L ~/Applications; then
        rm ~/Applications
    elif test -L ~/Applications/Nix\ Apps; then
        rm ~/Applications/Nix\ Apps
    fi

    if test -L ~/.nix-defexpr/channels/darwin; then
        nix-channel --remove darwin || true
    fi
  '';

  system.activationScripts.postActivation.text = mkAfter ''
    if test -L /etc/static; then
        rm /etc/static
    fi

    if test -O /nix/store; then
        l=$(readlink /Library/LaunchDaemons/org.nixos.nix-daemon.plist) || true
        if test "$l" != "/nix/var/nix/profiles/default/Library/LaunchDaemons/org.nixos.nix-daemon.plist"; then
            sudo launchctl remove org.nixos.nix-daemon 2> /dev/null || true
            sudo ln -sfn /nix/var/nix/profiles/default/Library/LaunchDaemons/org.nixos.nix-daemon.plist /Library/LaunchDaemons/org.nixos.nix-daemon.plist
            sudo launchctl load -w /Library/LaunchDaemons/org.nixos.nix-daemon.plist
        fi

        if ! grep -q etc/profile.d/nix-daemon.sh /etc/bashrc; then
            echo >&2 "Found no nix-daemon.sh reference in /etc/bashrc"
            echo >&2 "add this snippet back to /etc/bashrc:"
            echo >&2
            echo >&2 "    # Nix"
            echo >&2 "    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then"
            echo >&2 "      . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'"
            echo >&2 "    fi"
            echo >&2 "    # End Nix"
            echo >&2
        fi
    fi
  '';
}
