{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.environment;

  exportVariables =
    mapAttrsToList (n: v: ''export ${n}="${v}"'') cfg.variables;

  aliasCommands =
    mapAttrsFlatten (n: v: ''alias ${n}="${v}"'') cfg.shellAliases;


in {
  options = {

    environment.systemPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      example = literalExample "[ pkgs.nix-repl pkgs.vim ]";
      description = ''
        The set of packages that appear in
        /run/current-system/sw.  These packages are
        automatically available to all users, and are
        automatically updated every time you rebuild the system
        configuration.  (The latter is the main difference with
        installing them in the default profile,
        <filename>/nix/var/nix/profiles/default</filename>.
      '';
    };

    environment.systemPath = mkOption {
      type = types.loeOf types.path;
      default = (reverseList cfg.profiles) ++ [ "/usr/local" "/usr" "" ];
      description = ''
        The set of paths that are added to PATH
      '';
      apply = x: if isList x then makeBinPath x else x;
    };

    environment.profiles = mkOption {
      type = types.listOf types.str;
      default =
        [ # Use user, default and system profiles.
          "$HOME/.nix-profile"
          "/nix/var/nix/profiles/default"
          "/run/current-system/sw"
        ];
      description = ''
        A list of profiles used to setup the global environment.
      '';
    };

    environment.extraOutputsToInstall = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "doc" "info" "devdoc" ];
      description = "List of additional package outputs to be symlinked into <filename>/run/current-system/sw</filename>.";
    };

    environment.loginShell = mkOption {
      type = types.str;
      default = "$SHELL";
      description = ''
        Configure default login shell.
      '';
    };

    environment.variables = mkOption {
      type = types.attrsOf (types.either types.str (types.listOf types.str));
      default = {};
      description = ''
        A set of environment variables used in the global environment.
        These variables will be set on shell initialisation.
        The value of each variable can be either a string or a list of
        strings.  The latter is concatenated, interspersed with colon
        characters.
      '';
      apply = mapAttrs (n: v: if isList v then concatStringsSep ":" v else v);
    };

    environment.shellAliases = mkOption {
      type = types.attrsOf types.str;
      default = {};
      example = { ll = "ls -l"; };
      description = ''
        An attribute set that maps aliases (the top level attribute names in
        this option) to command strings or directly to build outputs. The
        alises are added to all users' shells.
      '';
    };

    environment.extraInit = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Shell script code called during global environment initialisation
        after all variables and profileVariables have been set.
        This code is asumed to be shell-independent, which means you should
        stick to pure sh without sh word split.
      '';
    };

    environment.interactiveShellInit = mkOption {
      default = "";
      description = ''
        Shell script code called during interactive shell initialisation.
        This code is asumed to be shell-independent, which means you should
        stick to pure sh without sh word split.
      '';
      type = types.lines;
    };

  };

  config = {

    system.build.setEnvironment = concatStringsSep "\n" exportVariables;
    system.build.setAliases = concatStringsSep "\n" aliasCommands;

    system.path = pkgs.buildEnv {
      name = "system-path";
      paths = cfg.systemPackages;
      inherit (cfg) extraOutputsToInstall;
    };

    environment.extraInit = ''
       # reset TERM with new TERMINFO available (if any)
       export TERM=$TERM

       export NIX_USER_PROFILE_DIR="/nix/var/nix/profiles/per-user/$USER"
       export NIX_PROFILES="${concatStringsSep " " (reverseList cfg.profiles)}"
    '';

    environment.variables =
      { GIT_SSL_CAINFO = mkDefault "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        SSL_CERT_FILE = mkDefault "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        EDITOR = mkDefault "nano";
        PAGER = mkDefault "less -R";
      };

  };
}
