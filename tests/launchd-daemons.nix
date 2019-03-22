{ config, pkgs, ... }:

{
  launchd.daemons.foo.command = "foo";
  launchd.agents.bar.command = "bar";
  launchd.user.agents.baz.command = "baz";

  test = ''
    echo "checking launchd load in /activate" >&2
    grep "launchctl load .* '/Library/LaunchDaemons/org.nixos.foo.plist" ${config.out}/activate
    grep "launchctl load .* '/Library/LaunchAgents/org.nixos.bar.plist" ${config.out}/activate
    echo "checking launchd load in /activate-user" >&2
    grep "launchctl load .* ~/Library/LaunchAgents/org.nixos.baz.plist" ${config.out}/activate-user
    echo "checking LaunchAgents creation /activate-user" >&2
    grep "mkdir -p ~/Library/LaunchAgents" ${config.out}/activate-user
  '';
}
