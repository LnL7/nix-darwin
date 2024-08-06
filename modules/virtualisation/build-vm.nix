{ config, extendModules, lib, ... }:
let

  inherit (lib) mkOption;

  vmVariant = extendModules {
    modules = [ ./tart-vm.nix ];
  };
in
{
  options = {

    virtualisation.vmVariant = mkOption {
      description = ''
        Machine configuration to be added for the vm script produced by `darwin-rebuild build-vm`.
      '';
      inherit (vmVariant) type;
      default = {};
      visible = "shallow";
    };

  };

  config = {

    system.build = {
      vm = lib.mkDefault config.virtualisation.vmVariant.system.build.vm;
    };

  };
}

