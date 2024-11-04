{ lib, ... }:

with lib;

{
  # We are uninstalling, disable sanity checks.
  assertions = mkForce [];
  system.activationScripts.checks.text = mkForce "";

  environment.etc = mkForce {};
  launchd.agents = mkForce {};
  launchd.daemons = mkForce {};
  launchd.user.agents = mkForce {};

  system.activationScripts.postUserActivation.text = mkAfter ''
    if [[ -L ~/.nix-defexpr/channels/darwin ]]; then
        nix-channel --remove darwin || true
    fi
  '';

  system.activationScripts.postActivation.text = mkAfter ''
    if [[ -L /Applications/Nix\ Apps ]]; then
        rm /Applications/Nix\ Apps
    fi

    if [[ -L /etc/static ]]; then
        rm /etc/static
    fi

    # If the Nix Store is owned by root then we're on a multi-user system
    if [[ -O /nix/store ]]; then
        if [[ -e /nix/var/nix/profiles/default/Library/LaunchDaemons/org.nixos.nix-daemon.plist ]]; then
            sudo cp /nix/var/nix/profiles/default/Library/LaunchDaemons/org.nixos.nix-daemon.plist /Library/LaunchDaemons/org.nixos.nix-daemon.plist
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

    # grep will return 1 when no lines matched which makes this line fail with `set -eo pipefail`
    dscl . -list /Users UserShell | { grep "\s/run/" || true; } | awk '{print $1}' | while read -r user; do
      shell=$(dscl . -read /Users/"$user" UserShell)
      if [[ "$shell" != */bin/zsh ]]; then
        echo >&2 "warning: changing $user's shell from $shell to /bin/zsh"
      fi

      dscl . -create /Users/"$user" UserShell /bin/zsh
    done
  '';
}
