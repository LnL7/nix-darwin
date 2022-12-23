{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.math-symbols-input;
  package = pkgs.callPackage ./package { };
  commands-to-plist = pkgs.callPackage ./commands-to-plist.nix { };
  # module = types.submoduleWith { description = "Math Symbols Input"; };

in {

  options.services.math-symbols-input = {
    enable = mkEnableOption ''
      LaTeX-style mathematical symbols input method for macOS
    '';

    symbols = mkOption {
      type = types.attrs;
      default = { };
      example = literalExample ''
        {
          "xd" = "😆";
        }
      '';
      description = "Custom symbols to add to Math Symbols Input";
    };
  };

  # Note that this only makes sense for homebrew
  config = mkIf cfg.enable {
    system.activationScripts.preActivation.text = ''
      echo "Setting up Math Symbols Input"

      rm /Library/Input\ Methods/Math\ Symbols\ Input.app
      rm ~/Library/Preferences/com.mathsymbolsinput.inputmethod.MathSymbolsInput.plist

      ln -s ${package}/Math\ Symbols\ Input.app /Library/Input\ Methods/
      ln -s ${
        commands-to-plist cfg.symbols
      }/com.mathsymbolsinput.inputmethod.MathSymbolsInput.plist ~/Library/Preferences/
    '';
  };
}
