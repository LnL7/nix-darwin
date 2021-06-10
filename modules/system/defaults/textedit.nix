{ config, lib, ... }:

with lib;

{
  options = {

    system.defaults.textedit.RichText = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to compose new documents as rich text or plain text.  The default is true (rich text).
      '';
    };

    system.defaults.textedit.NSFont = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "Helvetica";
      description = ''
        Set the font for rich text documents. 
      '';
    };

    system.defaults.textedit.NSFontSize = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        Set the font size for rich text documents.
      '';
    };

    system.defaults.textedit.NSFixedPitchFont = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "Menlo-Regular";
      description = ''
        Set the font for plain text documents. 
      '';
    };

    system.defaults.textedit.NSFixedPitchFontSize = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        Set the font size for plain text documents.
      '';
    };
  };
}
