{ config, pkgs, lib, ... }:

with lib;

let
  inherit (pkgs) stdenv;

  cfg = config.darwin-rebuild;

  extraPath = lib.makeBinPath [ cfg.nixPackage pkgs.coreutils pkgs.jq ];

  writeProgram = name: env: src:
    pkgs.substituteAll ({
      inherit name src;
      dir = "bin";
      isExecutable = true;
    } // env);

  darwin-option = writeProgram "darwin-option"
    {
      inherit (config.system) profile;
      inherit (stdenv) shell;
    }
    ../../pkgs/nix-tools/darwin-option.sh;

  darwin-rebuild = writeProgram "darwin-rebuild"
    {
      inherit (config.system) profile;
      inherit (stdenv) shell;
      path = "${extraPath}:${config.environment.systemPath}";
    }
    ../../pkgs/nix-tools/darwin-rebuild.sh;
in

{
  options = {
    darwin-rebuild.nixPackage = mkOption {
      type = types.either types.package types.path;
      default = config.nix.package;
      defaultText = "config.nix.package";
      example = literalExample "pkgs.nixUnstable";
      description = ''
        This option specifies the package or profile that contains the version of Nix used by <literal>darwin-rebuild</literal>. The default is to use the system version of Nix.
      '';
    };
  };

  config = {

    environment.systemPackages =
      [ # Include nix-tools by default
        darwin-option
        darwin-rebuild
      ];

  };
}
