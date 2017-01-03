{ config, lib, pkgs, ...}:

with lib;

let

  cfge = config.environment;

  cfg = config.programs.fish;

  fishVariables =
    mapAttrsToList (n: v: ''set -x ${n} "${v}"'') cfg.variables;

  shell = pkgs.runCommand pkgs.fish.name
    { buildInputs = [ pkgs.makeWrapper ]; }
    ''
      source $stdenv/setup

      mkdir -p $out/bin
      makeWrapper ${pkgs.fish}/bin/fish $out/bin/fish
    '';

  fishAliases = concatStringsSep "\n" (
    mapAttrsFlatten (k: v: "alias ${k} '${v}'") cfg.shellAliases
  );

in

{

  options = {

    programs.fish = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to configure fish as an interactive shell.
        '';
      };

      variables = mkOption {
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

      shellAliases = mkOption {
        type = types.attrs;
        default = cfge.shellAliases;
        description = ''
          Set of aliases for fish shell. See <option>environment.shellAliases</option>
          for an option format description.
        '';
      };

      shellInit = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Shell Script code called during fish shell initialisation.
        '';
      };

      loginShellInit = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Shell script code called during fish login shell initialisation.
        '';
      };

      interactiveShellInit = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Shell script code called during interactive fish shell initialisation.
        '';
      };

      promptInit = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Shell script code used to initialise fish prompt.
        '';
      };

    };
  };

  config = mkIf cfg.enable {

    environment.etc."fish/foreign-env/shellInit".text = cfge.shellInit;
    environment.etc."fish/foreign-env/loginShellInit".text = cfge.loginShellInit;
    environment.etc."fish/foreign-env/interactiveShellInit".text = cfge.interactiveShellInit;

    environment.etc."fish/config.fish".text = ''
      # /etc/fish/config.fish: DO NOT EDIT -- this file has been generated automatically.

      set fish_function_path $fish_function_path ${pkgs.fish-foreign-env}/share/fish-foreign-env/functions

      set PATH ${replaceStrings [":"] [" "] config.environment.systemPath} $PATH

      ${config.system.build.setEnvironment}

      fenv source /etc/fish/foreign-env/shellInit > /dev/null

      ${cfg.shellInit}

      ${concatStringsSep "\n" fishVariables}

      if status --is-login
        fenv source /etc/fish/foreign-env/loginShellInit > /dev/null
        ${cfg.loginShellInit}
      end

      if status --is-interactive
        ${fishAliases}
        fenv source /etc/fish/foreign-env/interactiveShellInit > /dev/null
        ${cfg.interactiveShellInit}
        ${cfg.promptInit}
      end
    '';

    # include programs that bring their own completions
    # FIXME: environment.pathsToLink = [ "/share/fish/vendor_completions.d" ];

    environment.systemPackages = [ pkgs.fish ];

    environment.loginShell = mkDefault "${shell}/bin/fish -l";
    environment.variables.SHELL = mkDefault "${shell}/bin/fish";

  };

}
