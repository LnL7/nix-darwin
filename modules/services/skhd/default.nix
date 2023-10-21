{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.skhd;

  validateKeybinding = binding:
    let
      matched = builtins.match "([a-z|0-9]+( [+] [a-z|0-9]+){0,} - [a-z|0-9]+)" binding;

      isCorrect =
        # Some groups are optional
        if isList matched then
          builtins.any (group: isString group) matched
        else matched != null;
    in
    if isCorrect then isCorrect
    # Throw here to show the name of the faulty attribute
    else throw "attribute with name '${binding}' in 'services.skhd.keybindings' is incorrectly formatted";

  mkKeyBindings = concatStrings
    (mapAttrsToList (name: value: "${name} : ${value}\n") cfg.keybindings);

  mkBlacklist = ".blacklist [\n  \"${concatStringsSep "\"\n  \"" cfg.blacklist}\"\n]";

  configFile = optionalString (cfg.keybindings != [ ]) mkKeyBindings
    + optionalString (cfg.blacklist != [ ]) mkBlacklist
    + cfg.extraConfig;
in
{
  imports = [
    (mkRenamedOptionModule [ "services" "skhd" "skhdConfig" ] [ "services" "skhd" "extraConfig" ])
  ];

  options.services.skhd = {
    enable = mkEnableOption "skhd hotkey daemon";

    package = mkOption {
      type = types.package;
      default = pkgs.skhd;
      description = "The skhd package to use.";
      example = literalExpression "pkgs.skhd";
    };

    blacklist = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Prevent skhd from monitoring events for specific applications.
      '';
      example = literalExpression ''
        [
          "firefox"
          "kitty"
        ]
      '';
    };

    keybindings = mkOption {
      type = with types; addCheck (attrsOf (either str path)) (attrs:
        builtins.all (name: validateKeybinding name) (attrNames attrs)
      );
      default = { };
      description = ''
        A list of keybindings to add to shkd. See the
        <link xlink:href="https://github.com/koekeishiya/skhd/blob/master/examples/skhdrc">example configuration</link>
        for more information and examples on how to use this. The generated file
        will get written to <filename>/etc/skhdrc</filename>.
      '';
      example = literalExpression ''
        {
          "ctl + alt - h" = "echo foo";
          "shift - f" = "echo bar";
        }
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = "alt + shift - r : chunkc quit";
      description = ''
        Extra configuration to append to the generated <filename>skhdrc</filename>.
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    environment.etc."skhdrc".text = configFile;

    launchd.user.agents.skhd = {
      path = [ config.environment.systemPath ];

      serviceConfig = {
        ProgramArguments = toList "${cfg.package}/bin/skhd"
          ++ optionals (configFile != "") [ "-c" "/etc/skhdrc" ];
        KeepAlive = true;
        ProcessType = "Interactive";
      };
    };
  };
}
