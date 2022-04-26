{ lib, ... }:

with lib;
{
  options = {
    serverAliases = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "www.example.org" "example.org" ];
      description = ''
        Additional names of virtual hosts served by this virtual host configuration.
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        These lines go into the vhost verbatim
      '';
    };
  };
}
