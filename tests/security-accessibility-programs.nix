{ config, pkgs, ... }:

{
  security.accessibilityPrograms = [ "${pkgs.hello}/bin/hello" ];

  test = ''
    echo checking sqlite command in /activate >&2
    grep "/usr/bin/sqlite3 /Library/Application\\\\ Support/com.apple.TCC/TCC.db" ${config.out}/activate
    echo checking sqlite queries /activate >&2
    grep "INSERT or REPLACE INTO access VALUES ('kTCCServiceAccessibility','${pkgs.hello}/bin/hello',1,1,1,NULL,NULL)" ${config.out}/activate
    grep "DELETE FROM access WHERE client LIKE '/nix/store/%' AND client NOT IN ('${pkgs.hello}/bin/hello')" ${config.out}/activate
  '';
}
