{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.networking;

  hostnameRegEx = ''^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$'';

  emptyList = lst: if lst != [] then lst else ["empty"];
  quoteStrings = concatMapStringsSep " " (str: "'${str}'");

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
    networking.computerName = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "John’s MacBook Pro";
      description = ''
        The user-friendly name for the system, set in System Preferences > Sharing > Computer Name.

        Setting this option is equivalent to running `scutil --set ComputerName`.

        This name can contain spaces and Unicode characters.
      '';
    };

    networking.hostName = mkOption {
      type = types.nullOr (types.strMatching hostnameRegEx);
      default = null;
      example = "Johns-MacBook-Pro";
      description = ''
        The hostname of your system, as visible from the command line and used by local and remote
        networks when connecting through SSH and Remote Login.

        Setting this option is equivalent to running the command `scutil --set HostName`.

        (Note that networking.localHostName defaults to the value of this option.)
      '';
    };

    networking.localHostName = mkOption {
      type = types.nullOr (types.strMatching hostnameRegEx);
      default = cfg.hostName;
      example = "Johns-MacBook-Pro";
      description = ''
        The local hostname, or local network name, is displayed beneath the computer's name at the
        top of the Sharing preferences pane. It identifies your Mac to Bonjour-compatible services.

        Setting this option is equivalent to running the command `scutil --set LocalHostName`, where
        running, e.g., `scutil --set LocalHostName 'Johns-MacBook-Pro'`, would set
        the systems local hostname to "Johns-MacBook-Pro.local". The value of this option defaults
        to the value of the networking.hostName option.

        By default on macOS the local hostname is your computer's name with ".local" appended, with
        any spaces replaced with hyphens, and invalid characters omitted.
      '';
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

      ${optionalString (cfg.computerName != null) ''
        scutil --set ComputerName '${cfg.computerName}'
      ''}
      ${optionalString (cfg.hostName != null) ''
        scutil --set HostName '${cfg.hostName}'
      ''}
      ${optionalString (cfg.localHostName != null) ''
        scutil --set LocalHostName '${cfg.localHostName}'
      ''}

      ${setNetworkServices}
    '';

  };
}
