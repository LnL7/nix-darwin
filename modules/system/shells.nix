{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.environment;
in

{
  options = {
    environment.shells = mkOption {
      type = types.listOf (types.either types.shellPackage types.path);
      default = [];
      example = literalExpression "[ pkgs.bashInteractive pkgs.zsh ]";
      description = ''
        A list of permissible login shells for user accounts.
        No need to mention <literal>/bin/sh</literal>
        and other shells that are available by default on
        macOS.
      '';
      apply = map (v: if types.shellPackage.check v then "/run/current-system/sw${v.shellPath}" else v);
    };
  };

  config = mkIf (cfg.shells != []) {

    environment.etc."shells".text = ''
      # List of acceptable shells for chpass(1).
      # Ftpd will not allow users to connect who are not using
      # one of these shells.

      /bin/bash
      /bin/csh
      /bin/dash
      /bin/ksh
      /bin/sh
      /bin/tcsh
      /bin/zsh

      # List of shells managed by nix.
      ${concatStringsSep "\n" cfg.shells}
    '';

  };
}
