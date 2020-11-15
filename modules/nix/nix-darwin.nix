{ config, pkgs, lib, ... }:

with lib;

let
  inherit (pkgs) stdenv;

  extraPath = lib.makeBinPath [ config.nix.package pkgs.coreutils pkgs.jq ];

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
  config = {

    environment.systemPackages =
      [ # Include nix-tools by default
        darwin-option
        darwin-rebuild
      ];

  };
}
