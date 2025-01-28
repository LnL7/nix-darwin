{ config, ... }:

{
  nix.enable = false;
  nix.package = throw "`nix.package` used when `nix.enable` is turned off";

  test = ''
    printf >&2 'checking for unexpected Nix binary in /sw/bin\n'
    [[ -e ${config.out}/sw/bin/nix-env ]] && exit 1

    printf >&2 'checking for unexpected nix-daemon plist in /Library/LaunchDaemons\n'
    [[ -e ${config.out}/Library/LaunchDaemons/org.nixos.nix-daemon.plist ]] && exit 1

    printf >&2 'checking for late‐bound Nix lookup in /activate\n'
    grep nixEnvPath= ${config.out}/activate
  '';
}
