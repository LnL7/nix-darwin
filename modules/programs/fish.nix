{ config, lib, pkgs, ...}:

with lib;

let

  cfg = config.programs.fish;
  cfge = config.environment;

  foreignEnv = pkgs.writeText "fish-foreign-env" ''
    # TODO: environment.shellInit
    ${cfge.extraInit}
  '';

  loginForeignEnv = pkgs.writeText "fish-login-foreign-env" ''
    # TODO: environment.loginShellInit
  '';

  interactiveForeignEnv = pkgs.writeText "fish-interactive-foreign-env" ''
    ${cfge.interactiveShellInit}
  '';

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

  fishVariables =
    mapAttrsToList (n: v: ''set -x ${n} "${v}"'') cfg.variables;

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

    environment.systemPackages = [ pkgs.fish ];

    environment.pathsToLink = [ "/share/fish" ];

    environment.loginShell = mkDefault "${shell}/bin/fish -l";
    environment.variables.SHELL = mkDefault "${shell}/bin/fish";

    environment.etc."fish/config.fish".text = ''
      # /etc/fish/config.fish: DO NOT EDIT -- this file has been generated automatically.

      set fish_function_path $fish_function_path ${pkgs.fish-foreign-env}/share/fish-foreign-env/functions

      set PATH ${replaceStrings [":"] [" "] config.environment.systemPath} $PATH

      ${config.system.build.setEnvironment}

      fenv source ${foreignEnv}
      ${cfg.shellInit}

      ${concatStringsSep "\n" fishVariables}

      if status --is-login
        # TODO: environment.loginShellInit
        ${cfg.loginShellInit}
      end

      if status --is-interactive
        ${fishAliases}
        ${optionalString (cfge.interactiveShellInit != "") ''
          fenv source ${interactiveForeignEnv}
        ''}

        ${cfg.interactiveShellInit}
        ${cfg.promptInit}
      end
    '';

  };

}
