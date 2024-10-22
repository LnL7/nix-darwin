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

  localhostMultiple = any (elem "localhost") (attrValues (removeAttrs cfg.hosts [ "127.0.0.1" "::1" ]));
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
        hardware ports, use {command}`networksetup -listallnetworkservices`.
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

    networking.hosts = lib.mkOption {
      type = types.attrsOf (types.listOf types.str);
      example = literalExpression ''
        {
          "127.0.0.1" = [ "foo.bar.baz" ];
          "192.168.0.2" = [ "fileserver.local" "nameserver.local" ];
        };
      '';
      description = ''
        Locally defined maps of hostnames to IP addresses.
      '';
      default = {};
    };

    networking.hostFiles = lib.mkOption {
      type = types.listOf types.path;
      defaultText = literalMD "Hosts from {option}`networking.hosts` and {option}`networking.extraHosts`";
      example = literalExpression ''[ "''${pkgs.my-blocklist-package}/share/my-blocklist/hosts" ]'';
      description = ''
        Files that should be concatenated together to form {file}`/etc/hosts`.
      '';
    };

    networking.extraHosts = lib.mkOption {
      type = types.lines;
      default = "";
      example = "192.168.0.1 lanlocalhost";
      description = ''
        Additional verbatim entries to be appended to {file}`/etc/hosts`.
        For adding hosts from derivation results, use {option}`networking.hostFiles` instead.
      '';
    };
  };

  config = {
    assertions = [{
      assertion = !localhostMultiple;
      message = ''
        `networking.hosts` maps "localhost" to something other than "127.0.0.1"
        or "::1". This will break some applications. Please use
        `networking.extraHosts` if you really want to add such a mapping.
      '';
    }];

    warnings = [
      (mkIf (cfg.knownNetworkServices == [] && cfg.dns != []) "networking.knownNetworkServices is empty, dns servers will not be configured.")
      (mkIf (cfg.knownNetworkServices == [] && cfg.search != []) "networking.knownNetworkServices is empty, dns searchdomains will not be configured.")
    ];

    system.activationScripts.networking.text = ''
      echo "configuring networking..." >&2

      ${optionalString (cfg.computerName != null) ''
        scutil --set ComputerName ${escapeShellArg cfg.computerName}
      ''}
      ${optionalString (cfg.hostName != null) ''
        scutil --set HostName ${escapeShellArg cfg.hostName}
      ''}
      ${optionalString (cfg.localHostName != null) ''
        scutil --set LocalHostName ${escapeShellArg cfg.localHostName}
      ''}

      ${setNetworkServices}
    '';

    networking.hostFiles = let
      # Note: localhostHosts has to appear first in /etc/hosts so that 127.0.0.1
      # resolves back to "localhost" (as some applications assume) instead of
      # the FQDN!
      localhostHosts = pkgs.writeText "localhost-hosts" ''
        ##
        # Host Database
        #
        # localhost is used to configure the loopback interface
        # when the system is booting.  Do not change this entry.
        ##
        127.0.0.1	localhost
        255.255.255.255	broadcasthost
        ::1             localhost
      '';
      stringHosts =
        let
          oneToString = set: ip: ip + " " + concatStringsSep " " set.${ip} + "\n";
          allToString = set: concatMapStrings (oneToString set) (attrNames set);
        in pkgs.writeText "string-hosts" (allToString (filterAttrs (_: v: v != []) cfg.hosts));
      extraHosts = pkgs.writeText "extra-hosts" cfg.extraHosts;
    in mkBefore [ localhostHosts stringHosts extraHosts ];

    environment.etc.hosts = {
      knownSha256Hashes = [
        "c7dd0e2ed261ce76d76f852596c5b54026b9a894fa481381ffd399b556c0e2da"
      ];

      source = pkgs.concatText "hosts" cfg.hostFiles;
    };
  };
}
