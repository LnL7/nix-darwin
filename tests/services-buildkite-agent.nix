{ config, pkgs, ... }:

let
  buildkite-agent = pkgs.runCommand "buildkite-agent-0.0.0" { } "mkdir $out";
  tokenPath = pkgs.writeText "buildkite_token" "TEST_TOKEN";
in

{
  services.buildkite-agents.test = {
    enable = true;
    package = buildkite-agent;
    extraConfig = "yolo=1";
    privateSshKeyPath = "/dev/null";
    hooks.command = "echo test hook";
    inherit tokenPath;
  };

  test = ''
    echo "checking buildkite-agent-test service in /Library/LaunchDaemons" >&2
    grep "org.nixos.buildkite-agent-test" ${config.out}/Library/LaunchDaemons/org.nixos.buildkite-agent-test.plist

    echo "checking creation of buildkite-agent service config" >&2
    script=$(cat ${config.out}/Library/LaunchDaemons/org.nixos.buildkite-agent-test.plist | awk -F'[< ]' '$6 ~ "^/nix/store/.*" {print $6}')
    grep "yolo=1" "$script"
    grep "${tokenPath}" "$script"

    echo "checking that a buildkite-agent hook works" >&2
    hooks_path=$(cat $script | awk -F'"' '/^hooks-path/ {print $2;}')
    $hooks_path/command | grep test
  '';
}
