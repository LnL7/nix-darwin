{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.nix-index;
  command-not-found-script = "${cfg.package}/etc/profile.d/command-not-found.sh";
in

{
  options = {
    programs.nix-index.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable nix-index and its command-not-found helper.";
    };

    programs.nix-index.package = mkOption {
      type = types.package;
      default = pkgs.nix-index;
      defaultText = "pkgs.nix-index";
      description = "This option specifies the nix-index package to use.";
    };
  };


  config = mkIf config.programs.nix-index.enable {

    environment.systemPackages = [ cfg.package ];

    environment.interactiveShellInit = "source ${command-not-found-script}";

    programs.fish.interactiveShellInit = ''
      function __fish_command_not_found_handler --on-event="fish_command_not_found"
        ${if config.programs.fish.useBabelfish then ''
        command_not_found_handle $argv
        '' else ''
        ${pkgs.bashInteractive}/bin/bash -c \
          "source ${command-not-found-script}; command_not_found_handle $argv"
        ''}
      end
    '';

  };
}
