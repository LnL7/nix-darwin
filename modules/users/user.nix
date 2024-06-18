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

    createHome = mkOption {
      type = types.bool;
      default = false;
      description = "Create the home directory when creating the user.";
    };

    initialPassword = mkOption {
      type = with types; nullOr str;
      default = null;
      description = ''
        Specifies the initial password for the user,
        i.e. the password assigned if the user does not already exist.
        If {option}`users.isHidden` is set to false,
        then the password is used for configuring a secure token for disk encryption.
      '';
    };

    shell = mkOption {
      type = types.either types.shellPackage types.path;
      default = "/sbin/nologin";
      example = literalExpression "pkgs.bashInteractive";
      description = "The user's shell.";
    };

    packages = mkOption {
      type = types.listOf types.package;
      default = [];
      example = literalExpression "[ pkgs.firefox pkgs.thunderbird ]";
      description = ''
        The set of packages that should be made availabe to the user.
        This is in contrast to {option}`environment.systemPackages`,
        which adds packages to all users.
      '';
    };
  };

  config = {

    name = mkDefault name;

  };
}
