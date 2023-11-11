# copied from https://github.com/NixOS/nixpkgs/blob/85f1ba3e51676fa8cc604a3d863d729026a6b8eb/nixos/modules/config/networking.nix
#
# if you get an error saying operation not permitted, run the following command:
# sudo chflags nouchg,noschg /etc/hosts
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkBefore;
  inherit (lib.lists) optional;
  inherit (lib.options) literalExpression literalMD;
  inherit (lib.attrsets) attrNames filterAttrs;
  inherit (lib.strings) concatStringsSep concatMapStrings;
  cfg = config.networking;
in {
  options = {
    networking.hosts = lib.mkOption {
      type = types.attrsOf (types.listOf types.str);
      example = literalExpression ''
        {
          "127.0.0.1" = [ "foo.bar.baz" ];
          "192.168.0.2" = [ "fileserver.local" "nameserver.local" ];
        };
      '';
      description = lib.mdDoc ''
        Locally defined maps of hostnames to IP addresses.
      '';
    };

    networking.hostFiles = lib.mkOption {
      type = types.listOf types.path;
      defaultText = literalMD "Hosts from {option}`networking.hosts` and {option}`networking.extraHosts`";
      example = literalExpression ''[ "''${pkgs.my-blocklist-package}/share/my-blocklist/hosts" ]'';
      description = lib.mdDoc ''
        Files that should be concatenated together to form {file}`/etc/hosts`.
      '';
    };

    networking.extraHosts = lib.mkOption {
      type = types.lines;
      default = "";
      example = "192.168.0.1 lanlocalhost";
      description = lib.mdDoc ''
        Additional verbatim entries to be appended to {file}`/etc/hosts`.
        For adding hosts from derivation results, use {option}`networking.hostFiles` instead.
      '';
    };
  };

  config = {
    networking.hosts = let
      hostnames =
        optional (cfg.hostName != "") cfg.hostName; # Then the hostname (without the domain)
    in {
      "127.0.0.1" = hostnames;
      "::1" = hostnames;
    };

    networking.hostFiles = let
      # Note: localhostHosts has to appear first in /etc/hosts so that 127.0.0.1
      # resolves back to "localhost" (as some applications assume) instead of
      # the FQDN! By default "networking.hosts" also contains entries for the
      # FQDN so that e.g. "hostname -f" works correctly.
      localhostHosts = pkgs.writeText "localhost-hosts" ''
        127.0.0.1       localhost
        ::1             localhost
        255.255.255.255 broadcasthost
      '';
      stringHosts = let
        oneToString = set: ip: ip + " " + concatStringsSep " " set.${ip} + "\n";
        allToString = set: concatMapStrings (oneToString set) (attrNames set);
      in
        pkgs.writeText "string-hosts" (allToString (filterAttrs (_: v: v != []) cfg.hosts));
      extraHosts = pkgs.writeText "extra-hosts" cfg.extraHosts;
    in
      mkBefore [localhostHosts stringHosts extraHosts];

    environment.etc.hosts = {
      copy = true;
      source = pkgs.concatText "hosts" cfg.hostFiles;
    };
  };
}
