{ lib, mkTextDerivation }:

{ config, name, ... }:

with lib;

let
  fileName = file: last (splitString "/" file);
  mkDefaultIf = cond: value: mkIf cond (mkDefault value);

  drv = mkTextDerivation (fileName name) config.text;
in

{
  options = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = lib.mdDoc ''
        Whether this file should be generated.
        This option allows specific files to be disabled.
      '';
    };

    text = mkOption {
      type = types.lines;
      default = "";
      description = lib.mdDoc ''
        Text of the file.
      '';
    };

    target = mkOption {
      type = types.str;
      default = name;
      description = lib.mdDoc ''
        Name of symlink.  Defaults to the attribute name.
      '';
    };

    source = mkOption {
      type = types.path;
      description = lib.mdDoc ''
        Path of the source file.
      '';
    };

    copy = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc ''
        Whether this file should be copied instead of symlinking.
      '';
    };

    knownSha256Hashes = mkOption {
      internal = true;
      type = types.listOf types.str;
      default = [];
    };

    force = mkOption {
      type = types.bool;
      default = false;
      internal = true;
      description = lib.mdDoc ''
        Whether this file should be replaced even if an unknown version of the file already exists.
      '';
    };
  };

  config = {

    source = mkDefault drv;

  };
}
