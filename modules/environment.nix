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
      default = [ "$HOME/.nix-profile" "/run/current-system/sw" "/nix/var/nix/profiles/default" "/usr/local" ];
      description = ''
        The set of paths that are added to PATH
      '';
      apply = x: if isList x then makeBinPath x else x;
    };

    environment.extraOutputsToInstall = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "doc" "info" "devdoc" ];
      description = "List of additional package outputs to be symlinked into <filename>/run/current-system/sw</filename>.";
    };

    environment.variables = mkOption {
      type = types.attrsOf (types.loeOf types.str);
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

  };

  config = {

    system.build.setEnvironment = concatStringsSep "\n" exportVariables;
    system.build.setAliases = concatStringsSep "\n" aliasCommands;

    system.path = pkgs.buildEnv {
      name = "system-path";
      paths = cfg.systemPackages;
      inherit (cfg) extraOutputsToInstall;
    };

  };
}
