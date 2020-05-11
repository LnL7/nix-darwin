{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.environment;

  exportVariables =
    mapAttrsToList (n: v: ''export ${n}="${v}"'') cfg.variables;

  aliasCommands =
    mapAttrsFlatten (n: v: ''alias ${n}="${v}"'') cfg.shellAliases;

  makeDrvBinPath = concatMapStringsSep ":" (p: if isDerivation p then "${p}/bin" else p);
in

{
  options = {
    environment.systemPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      example = literalExample "[ pkgs.curl pkgs.vim ]";
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
      type = types.listOf (types.either types.path types.str);
      description = "The set of paths that are added to PATH.";
      apply = x: if isList x then makeDrvBinPath x else x;
    };

    environment.profiles = mkOption {
      type = types.listOf types.str;
      description = "A list of profiles used to setup the global environment.";
    };

    environment.postBuild = mkOption {
      type = types.lines;
      default = "";
      description = "Commands to execute when building the global environment.";
    };

    environment.extraOutputsToInstall = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "doc" "info" "devdoc" ];
      description = "List of additional package outputs to be symlinked into <filename>/run/current-system/sw</filename>.";
    };

    environment.pathsToLink = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "/share/doc" ];
      description = "List of directories to be symlinked in <filename>/run/current-system/sw</filename>.";
    };

    environment.darwinConfig = mkOption {
      type = types.either types.path types.str;
      default = "$HOME/.nixpkgs/darwin-configuration.nix";
      description = ''
        The path of the darwin configuration.nix used to configure the system,
        this updates the default darwin-config entry in NIX_PATH. Since this
        changes an environment variable it will only apply to new shells.

        NOTE: Changing this requires running <command>darwin-rebuild switch -I darwin-config=/path/to/configuration.nix</command>
        the first time to make darwin-rebuild aware of the custom location.
      '';
    };

    environment.loginShell = mkOption {
      type = types.str;
      default = "$SHELL";
      description = "Configure default login shell.";
    };

    environment.variables = mkOption {
      type = types.attrsOf (types.either types.str (types.listOf types.str));
      default = {};
      example = { EDITOR = "vim"; LANG = "nl_NL.UTF-8"; };
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

    environment.shellInit = mkOption {
      default = "";
      description = ''
        Shell script code called during shell initialisation.
        This code is asumed to be shell-independent, which means you should
        stick to pure sh without sh word split.
      '';
      type = types.lines;
    };

    environment.loginShellInit = mkOption {
      default = "";
      description = ''
        Shell script code called during login shell initialisation.
        This code is asumed to be shell-independent, which means you should
        stick to pure sh without sh word split.
      '';
      type = types.lines;
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

    environment.systemPath = [ (makeBinPath cfg.profiles) "/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin" ];

    # Use user, default and system profiles.
    environment.profiles = mkMerge [
      (mkOrder 800 [ "$HOME/.nix-profile" ])
      [ "/run/current-system/sw" "/nix/var/nix/profiles/default" ]
    ];

    environment.pathsToLink = [ "/bin" "/share/locale" ];

    environment.extraInit = ''
       # reset TERM with new TERMINFO available (if any)
       export TERM=$TERM

       export NIX_USER_PROFILE_DIR="/nix/var/nix/profiles/per-user/$USER"
       export NIX_PROFILES="${concatStringsSep " " (reverseList cfg.profiles)}"
    '';

    environment.variables =
      {
        XDG_CONFIG_DIRS = map (path: path + "/etc/xdg") cfg.profiles;
        XDG_DATA_DIRS = map (path: path + "/share") cfg.profiles;
        EDITOR = mkDefault "nano";
        PAGER = mkDefault "less -R";
      };

    system.path = pkgs.buildEnv {
      name = "system-path";
      paths = cfg.systemPackages;
      inherit (cfg) postBuild pathsToLink extraOutputsToInstall;
    };

    system.build.setEnvironment = pkgs.writeText "set-environment" ''
      # Prevent this file from being sourced by child shells.
      export __NIX_DARWIN_SET_ENVIRONMENT_DONE=1

      export PATH=${config.environment.systemPath}
      ${concatStringsSep "\n" exportVariables}

      # Extra initialisation
      ${cfg.extraInit}
    '';

    system.build.setAliases = pkgs.writeText "set-aliases" ''
      ${concatStringsSep "\n" aliasCommands}
    '';

  };
}
