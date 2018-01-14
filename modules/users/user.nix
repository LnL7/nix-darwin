{ name, lib, ... }:

with lib;

{
  options = {
    name = mkOption {
      type = types.str;
      description = ''
        The name of the user account. If undefined, the name of the
        attribute set will be used.
      '';
    };

    description = mkOption {
      type = types.str;
      default = "";
      example = "Alice Q. User";
      description = ''
        A short description of the user account, typically the
        user's full name.
      '';
    };

    uid = mkOption {
      type = types.int;
      description = "The user's UID.";
    };

    gid = mkOption {
      type = types.int;
      default = 20;
      description = "The user's primary group.";
    };

    isHidden = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to make the user account hidden.";
    };

    # extraGroups = mkOption {
    #   type = types.listOf types.str;
    #   default = [];
    #   description = "The user's auxiliary groups.";
    # };

    home = mkOption {
      type = types.path;
      default = "/var/empty";
      description = "The user's home directory.";
    };

    shell = mkOption {
      type = types.either types.shellPackage types.path;
      default = "/sbin/nologin";
      example = literalExample "pkgs.bashInteractive";
      description = "The user's shell.";
    };
  };

  config = {

    name = mkDefault name;

  };
}
