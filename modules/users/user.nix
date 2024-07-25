{ name, config, lib, ... }:

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
      type = with types; nullOr int;
      default = null;
      description = "The account UID. If the UID is null, a free UID is picked on activation.";
    };

    gid = mkOption {
      type = with types; nullOr int;
      default = null;
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

    isTokenUser = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Indicates whether this user has a secure token capable of descrypting FileVault.
        Uses first alphabetical ordered admin with secure token enabled for the purpose of adding the token.
        Will prompt for a password from this user to grant the token.
      '';
    };

    isNormalUser = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Indicates whether this is an account for a “real” user.
        This automatically sets gid to 20, createHome to true,
        home to /home/«username», and isSystemUser to false.
        Exactly one of isNormalUser and isSystemUser must be true.
      '';
    };

    isAdminUser = mkOption {
      type = types.bool;
      default = false;
      description = "Indicates whether this is an account for an admin user.";
    };

    isSystemUser = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Indicates if the user is a system user or not.
        This option only has an effect if uid is null,
        in which case it determines whether the user’s UID is allocated in the range for system users
        (200-400) or in the range for normal users (starting at 501).
        Exactly one of isNormalUser and isSystemUser must be true.
      '';
    };

    initialPassword = mkOption {
      type = with types; nullOr str;
      default = null;
      description = ''
        Specifies the initial password for the user,
        i.e. the password assigned if the user does not already exist.
        If users.mutableUsers is true,
        the password can be changed subsequently using the sysadminctl command.
        Otherwise, it’s equivalent to setting the password option.
        The password specified here is world-readable in the Nix store,
        so it should only be used for guest accounts or passwords that will be changed promptly.
      '';
    };

    password = mkOption {
      type = with types; nullOr str;
      default = null;
      description = ''
        Specifies the (clear text) password for the user.
        Warning: do not set confidential information here because it is world-readable in the Nix store.
        This option should only be used for public accounts or with a Nix secrets manager.
        If users.mutableUsers is false, you cannot change user passwords,
        they will always be set according to the password options on next rebuild.
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

  config = mkMerge [
    { name = mkDefault name; }

    (mkIf config.isNormalUser {
      gid = mkDefault 20;
      createHome = mkDefault true;
      home = mkDefault "/Users/${config.name}";
      isSystemUser = mkDefault false;
    })

    {
      password = mkDefault (if config.initialPassword != null
        then "${config.initialPassword}" else "${config.password}");
    }
  ];
}
