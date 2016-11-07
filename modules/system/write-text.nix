{ lib, mkTextDerivation }:

with lib;

{ config, name, ... }:
let

  sourceDrv = mkTextDerivation name config.text;

in

{
  options = {

    enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether this /etc file should be generated.  This
        option allows specific /etc files to be disabled.
      '';
    };

    text = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Text of the file.
      '';
    };

    target = mkOption {
      type = types.str;
      default = name;
      description = ''
        Name of symlink (relative to
        <filename>/etc</filename>).  Defaults to the attribute
        name.
      '';
    };

    source = mkOption {
      type = types.path;
      description = ''
        Path of the source file.
      '';
    };

  };

  config = {

    source = mkIf (config.text != "") (mkDefault sourceDrv);

  };
}
