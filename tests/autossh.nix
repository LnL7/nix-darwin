{ config, pkgs, ... }:

{
  services.autossh.sessions = [ {
    name = "foo";
    user = "jfelice";
    extraArguments = "-i /some/key -T -N bar.eraserhead.net";
  } ];

  test = ''
    plist=${config.out}/Library/LaunchDaemons/org.nixos.autossh-foo.plist
    test -f $plist
    grep '<string>exec /nix/store/.*/bin/autossh ' $plist
    grep '<string>exec.*-i /some/key ' $plist
    tr -d '\n\t ' <$plist |grep '<key>KeepAlive</key><true */>'
  '';
}
