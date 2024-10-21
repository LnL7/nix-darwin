{ name, lib, ... }:

{
  options = let
    inherit (lib) literalExpression mkOption types;
  in {
    name = mkOption {
      type = types.str;
      default = name;
      description = ''
        The name of the user account. If undefined, the name of the
        attribute set will be used.
      '';
    };

    description = mkOption {
      type = types.nullOr types.nonEmptyStr;
      default = null;
      example = "Alice Q. User";
      description = ''
        A short description of the user account, typically the
        user's full name.

        This defaults to `null` which means, on creation, `sysadminctl`
        will pick the description which is usually always {option}`name`.

        Using an empty name is not supported and breaks macOS like
        making the user not appear in Directory Utility.
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
}
