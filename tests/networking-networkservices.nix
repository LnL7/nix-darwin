{ lib, config, ... }:

{
  networking.knownNetworkServices = [
    "Wi-Fi"
    "Thunderbolt Ethernet"
  ];
  networking.dns = [
    "8.8.8.8"
    "8.8.4.4"
  ];
  networking.location."Home Lab" = {
    search = [ "home.lab" ];
  };

  test = ''
    echo checking dns settings in /activate >&2

    grep "networksetup -switchtolocation ${lib.strings.escapeShellArg "Automatic"}" ${config.out}/activate
    grep "networksetup -setdnsservers 'Wi-Fi' '8.8.8.8' '8.8.4.4'" ${config.out}/activate
    grep "networksetup -setdnsservers 'Thunderbolt Ethernet' '8.8.8.8' '8.8.4.4'" ${config.out}/activate

    grep "networksetup -switchtolocation 'Home Lab'" ${config.out}/activate
    grep "networksetup -setdnsservers 'Wi-Fi' 'empty'" ${config.out}/activate
    grep "networksetup -setdnsservers 'Thunderbolt Ethernet' 'empty'" ${config.out}/activate

    echo checking searchdomain settings in /activate >&2

    grep "networksetup -setsearchdomains 'Wi-Fi' 'empty'" ${config.out}/activate
    grep "networksetup -setsearchdomains 'Thunderbolt Ethernet' 'empty'" ${config.out}/activate

    grep "networksetup -setsearchdomains 'Wi-Fi' 'home.lab'" ${config.out}/activate
    grep "networksetup -setsearchdomains 'Thunderbolt Ethernet' 'home.lab'" ${config.out}/activate
  '';
}
