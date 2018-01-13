{ name, lib, ... }:

with lib;

{
  options = {
    gid = mkOption {
      type = mkOptionType {
        name = "gid";
        check = t: isInt t && t > 501;
      };
      description = "The group's GID.";
    };

    name = mkOption {
      type = types.str;
      description = ''
        The group's name. If undefined, the name of the attribute set
        will be used.
      '';
    };

    description = mkOption {
      type = types.str;
      default = "";
      description = "The group's description.";
    };
  };

  config = {

    name = mkDefault name;

  };
}
