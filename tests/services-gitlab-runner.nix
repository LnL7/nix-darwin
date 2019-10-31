{ config, pkgs, ... }:

let
  ofborg = pkgs.runCommand "gitlab-runner-0.0.0" {} "mkdir $out";
in

{
  services.gitlab-runner.enable = true;

  test  = ''
    echo >&2 "checking gitlab-runner service in /Library/LaunchDaemons"
    grep "org.nixos.gitlab-runner" ${config.out}/Library/LaunchDaemons/org.nixos.gitlab-runner.plist

    echo >&2 "checking gitlab-runner WorkingDirectory in /Library/LaunchDaemons"
    grep "/var/lib/gitlab-runner" ${config.out}/Library/LaunchDaemons/org.nixos.gitlab-runner.plist 

    echo >&2 "checking for user in /activate"
    grep "gitlab-runner" ${config.out}/activate
  '';
}
