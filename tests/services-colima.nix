{ config, pkgs, ... }:

let
  colima = pkgs.runCommand "colima-0.0.0" { } "mkdir $out";
in

{
  services.colima = {
    enable = true;
    enableDockerCompatability = true;
    package = colima;
    groupMembers = [ "john" "jane" ];
  };

  test = ''
    echo "checking colima service in /Library/LaunchDaemons" >&2
    grep "org.nixos.colima" ${config.out}/Library/LaunchDaemons/org.nixos.colima.plist
    grep "${colima}/bin/dnsmasq" ${config.out}/Library/LaunchDaemons/org.nixos.colima.plist

    echo "checking colima docker compat service in /Library/LaunchDaemons" >&2
    grep "org.nixos.colima-docker-compat" ${config.out}/Library/LaunchDaemons/org.nixos.colima-docker-compat.plist

    echo "checking colima config" >&2
    grep -F "--foreground" ${config.out}/Library/LaunchDaemons/org.nixos.colima.plist
    grep -F "--runtime docker" ${config.out}/Library/LaunchDaemons/org.nixos.colima.plist
    grep -F "--architectue host" ${config.out}/Library/LaunchDaemons/org.nixos.colima.plist

    echo "checking user creation in /activate" >&2
    grep "sysadminctl -addUser ${lib.escapeShellArgs [ "foo" "-UID" config.ids.uids.colima "-GID" config.ids.uids._colima "-fullName" "colima" "-home" "/var/lib/colima" "-shell" "/bin/bash" ]}" ${config.out}/activate
    grep "createhomedir -cu ${lib.escapeShellArg "colima"}" ${config.out}/activate
    grep "sysadminctl -addUser ${lib.escapeShellArgs [ "colima" "-UID" config.ids.uids.colima ]} .* ${lib.escapeShellArgs [ "-shell" "/bin/bash" ] }" ${config.out}/activate
    grep "sysadminctl -addUser ${lib.escapeShellArg "colima"} .* ${lib.escapeShellArgs [ "-home" "/var/lib/colima" ]}" ${config.out}/activate
    (! grep "dscl . -delete ${lib.escapeShellArg "/Users/colima"}" ${config.out}/activate)
    (! grep "dscl . -delete ${lib.escapeShellArg "/Groups/_colima"}" ${config.out}/activate)

    echo "checking group creation in /activate" >&2
    grep "dscl . -create ${lib.escapeShellArg "/Groups/_colima"} PrimaryGroupID ${builtins.toString config.ids.gids._colima}" ${config.out}/activate
    grep "dscl . -create ${lib.escapeShellArg "/Groups/_colima"} RealName ${lib.escapeShellArg "_colima"}" ${config.out}/activate
    grep "dscl . -create ${lib.escapeShellArg "/Groups/_colima"} PrimaryGroupID ${builtins.toString config.ids.gids._colima}" ${config.out}/activate
    (! grep "dscl . -delete ${lib.escapeShellArg "/Groups/_colima"}" ${config.out}/activate)

    echo "checking group membership in /activate" >&2
    grep "dscl . -create ${lib.escapeShellArg "/Groups/_colima"} GroupMembership ${lib.escapeShellArgs [ "john" "jane" ]}" ${config.out}/activate
  '';
}
