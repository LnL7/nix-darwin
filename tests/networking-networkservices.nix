{ config, pkgs, ... }:

{
  networking.knownNetworkServices = [ "Wi-Fi" "Thunderbolt Ethernet" ];
  networking.dns = [ "8.8.8.8" "8.8.4.4" ];

  test = ''
    echo checking dns settings in /activate >&2
    grep "networksetup -setdnsservers 'Wi-Fi' '8.8.8.8' '8.8.4.4'" ${config.out}/activate
    grep "networksetup -setdnsservers 'Thunderbolt Ethernet' '8.8.8.8' '8.8.4.4'" ${config.out}/activate
    echo checking empty searchdomain settings in /activate >&2
    grep "networksetup -setsearchdomains 'Wi-Fi' 'empty'" ${config.out}/activate
    grep "networksetup -setsearchdomains 'Thunderbolt Ethernet' 'empty'" ${config.out}/activate
  '';
}
