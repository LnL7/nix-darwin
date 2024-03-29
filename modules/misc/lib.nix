{ lib, ... }:

{
  options = {
    lib = lib.mkOption {
      default = { };

      type = lib.types.attrsOf lib.types.attrs;

      description = lib.mdDoc ''
        This option allows modules to define helper functions, constants, etc.
      '';
    };
  };
}
