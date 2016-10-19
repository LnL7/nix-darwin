{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.environment;

  exportVariables =
    mapAttrsToList (n: v: ''export ${n}="${v}"'') cfg.variables;

  exportedEnvVars =
    concatStringsSep "\n" exportVariables;

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

    environment.extraOutputsToInstall = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "doc" "info" "devdoc" ];
      description = "List of additional package outputs to be symlinked into <filename>/run/current-system/sw</filename>.";
    };

    environment.variables = mkOption {
      default = {};
      description = ''
        A set of environment variables used in the global environment.
        These variables will be set on shell initialisation.
        The value of each variable can be either a string or a list of
        strings.  The latter is concatenated, interspersed with colon
        characters.
      '';
      type = types.attrsOf (types.loeOf types.str);
      apply = mapAttrs (n: v: if isList v then concatStringsSep ":" v else v);
    };


  };

  config = {

    system.build.setEnvironment = pkgs.writeText "set-environment" ''
      ${exportedEnvVars}
    '';

    system.path = pkgs.buildEnv {
      name = "system-path";
      paths = cfg.systemPackages;
      inherit (cfg) extraOutputsToInstall;
    };

  };
}
