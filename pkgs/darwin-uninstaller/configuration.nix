{ lib, pkgs, ... }:

with lib;

{
  # We are uninstalling, disable sanity checks.
  assertions = mkForce [];
  system.activationScripts.checks.text = mkForce "";

  environment.etc = mkForce {};
  launchd.agents = mkForce {};
  launchd.daemons = mkForce {};
  launchd.user.agents = mkForce {};

  # Don't try to reload `nix-daemon`
  nix.useDaemon = mkForce false;

  system.activationScripts.postUserActivation.text = mkAfter ''
    nix-channel --remove darwin || true
  '';

  system.activationScripts.postActivation.text = mkAfter ''
    nix-channel --remove darwin || true

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
    fi

    # grep will return 1 when no lines matched which makes this line fail with `set -eo pipefail`
    dscl . -list /Users UserShell | { grep "\s/run/" || true; } | awk '{print $1}' | while read -r user; do
      shell=$(dscl . -read /Users/"$user" UserShell)
      if [[ "$shell" != */bin/zsh ]]; then
        echo >&2 "warning: changing $user's shell from $shell to /bin/zsh"
      fi

      dscl . -create /Users/"$user" UserShell /bin/zsh
    done

    while IFS= read -r -d "" file; do
      mv "$file" "''${file%.*}"
    done < <(find /etc -name '*.before-nix-darwin' -follow -print0)
  '';
}
