{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.security;

  runSQL = sql: ''/usr/bin/sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "${sql}"'';

  allowAccess = client: runSQL ''INSERT or REPLACE INTO access VALUES ('kTCCServiceAccessibility','${client}',1,1,1,NULL,NULL)'';
  revokeAccess = clients: runSQL ''DELETE FROM access WHERE client LIKE '/nix/store/%' AND client NOT IN (${concatMapStringsSep "," (s: "'${s}'") clients})'';

in

{
  options = {
    security.accessibilityPrograms = mkOption {
      type = types.listOf types.path;
      default = [];
      description = "List of nix programs that are allowed control through the accessibility APIs.";
    };
  };

  config = {

    system.activationScripts.accessibility.text = ''
      # Set up programs that require accessibility permissions
      echo "setting up accessibility programs..." >&2

      ${revokeAccess cfg.accessibilityPrograms}
      ${concatMapStringsSep "\n" allowAccess cfg.accessibilityPrograms}
    '';

  };
}
