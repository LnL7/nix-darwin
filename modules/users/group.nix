{ name, lib, ... }:

with lib;

{
  options = {
    name = mkOption {
      type = types.str;
      description = lib.mdDoc ''
        The group's name. If undefined, the name of the attribute set
        will be used.
      '';
    };

    gid = mkOption {
      type = mkOptionType {
        name = "gid";
        check = t: isInt t && t > 501;
      };
      description = lib.mdDoc "The group's GID.";
    };

    members = mkOption {
      type = types.listOf types.str;
      default = [];
      description = lib.mdDoc "The group's members.";
    };

    description = mkOption {
      type = types.str;
      default = "";
      description = lib.mdDoc "The group's description.";
    };
  };

  config = {

    name = mkDefault name;

  };
}
