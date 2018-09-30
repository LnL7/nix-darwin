{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.fonts;
in {
  options = {
    fonts = {
      enableFontDir = mkOption {
        default = false;
        description = ''
          Whether to create a directory with links to all fonts in
          <filename>/run/current-system/sw/share/fonts</filename>.
        '';
      };
      fonts = mkOption {
        type = types.listOf types.path;
        default = [];
        example = literalExample "[ pkgs.dejavu_fonts ]";
        description = "List of primary font paths.";
      };
    };
  };
  
  config = mkIf cfg.enableFontDir {
    system.build.fonts = pkgs.buildEnv {
      name = "system-fonts";
      paths = cfg.fonts;
      pathsToLink = "/share/fonts/truetype";
    };
    system.activationScripts.fonts.text = ''
      # Set up fonts.
      echo "setting up fonts..." >&2
      /bin/ln -hf ${config.system.build.fonts}/share/fonts/truetype/* /Library/Fonts/
      '';
    environment.pathsToLink = [ "/share/fonts/truetype" ];
  };

}
