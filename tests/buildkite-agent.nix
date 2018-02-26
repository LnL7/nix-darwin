{ config, pkgs, ... }:

let
  tokenPath = pkgs.writeText "buildkite_token" "TEST_TOKEN";
in {
  services.buildkite-agent = {
    enable = true;
    extraConfig = "yolo=1";
    openssh.privateKeyPath = "/dev/null";
    openssh.publicKeyPath = "/dev/null";
    hooks.command = "echo test";
    inherit tokenPath;
  };

  test = ''
    echo "checking buildkite-agent service in /Library/LaunchDaemons" >&2
    grep "org.nixos.buildkite-agent" ${config.out}/Library/LaunchDaemons/org.nixos.buildkite-agent.plist

    echo "checking creation of buildkite-agent service config" >&2
    script=$(cat ${config.out}/Library/LaunchDaemons/org.nixos.buildkite-agent.plist | awk -F'[< ]' '$3 ~ "^/nix/store/.*" {print $3}')
    grep "yolo=1" "$script"
    grep "${tokenPath}" "$script"
  '';
}
