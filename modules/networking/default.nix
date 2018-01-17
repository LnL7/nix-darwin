{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.networking;

  emptyList = lst: if lst != [] then lst else ["empty"];
  quoteStrings = concatMapStringsSep " " (str: "'${str}'");

  setHostName = optionalString (cfg.hostName != null) ''
    scutil --set ComputerName '${cfg.hostName}'
    scutil --set LocalHostName '${cfg.hostName}'
    scutil --set HostName '${cfg.hostName}'
  '';

  setNetworkServices = optionalString (cfg.knownNetworkServices != []) ''
    networkservices=$(networksetup -listallnetworkservices)
    ${concatMapStringsSep "\n" (srv: ''
      case "$networkservices" in
        *'${srv}'*)
          networksetup -setdnsservers '${srv}' ${quoteStrings (emptyList cfg.dns)}
          networksetup -setsearchdomains '${srv}' ${quoteStrings (emptyList cfg.search)}
          ;;
      esac
    '') cfg.knownNetworkServices}
  '';
in

{
  options = {
    networking.hostName = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "myhostname";
      description = "Hostname for your machine.";
    };

    networking.knownNetworkServices = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "Wi-Fi" "Ethernet Adaptor" "Thunderbolt Ethernet" ];
      description = ''
        List of networkservices that should be configured.

        To display a list of all the network services on the server's
        hardware ports, use <command>networksetup -listallnetworkservices</command>.
      '';
    };

    networking.dns = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "8.8.8.8" "8.8.4.4" "2001:4860:4860::8888" "2001:4860:4860::8844" ];
      description = "The list of dns servers used when resolving domain names.";
    };

    networking.search = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "The list of search paths used when resolving domain names.";
    };
  };

  config = {

    warnings = [
      (mkIf (cfg.knownNetworkServices == [] && cfg.dns != []) "networking.knownNetworkServices is empty, dns servers will not be configured.")
      (mkIf (cfg.knownNetworkServices == [] && cfg.search != []) "networking.knownNetworkServices is empty, dns searchdomains will not be configured.")
    ];

    system.activationScripts.networking.text = ''
      echo "configuring networking..." >&2

      ${setHostName}
      ${setNetworkServices}
    '';

  };
}
