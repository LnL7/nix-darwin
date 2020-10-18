{
  # WARNING this is very much still experimental.
  description = "A collection of darwin modules";

  outputs = { self, nixpkgs }:
  let
    versionsModule = { lib, ... }: {
      _file = ./flake.nix;
      config = {
        system.darwinVersionSuffix = ".${nixpkgs.shortRev or "dirty"}";
        system.darwinRevision = lib.mkIf (self ? rev) self.rev;

        system.nixpkgsVersionSuffix = ".${lib.substring 0 8 (nixpkgs.lastModifiedDate or nixpkgs.lastModified or "19700101")}.${nixpkgs.shortRev or "dirty"}";
        system.nixpkgsRevision = lib.mkIf (nixpkgs ? rev) nixpkgs.rev;
      };
    };
  in
  {

    lib = {
      # TODO handle multiple architectures.
      evalConfig = import ./eval-config.nix { inherit (nixpkgs) lib; };

      darwinSystem = { modules, inputs ? {}, ... }@args: self.lib.evalConfig (args // {
        inputs = { inherit nixpkgs; darwin = self; } // inputs;
        modules = modules ++ [ versionsModule ];
      });
    };

    darwinModules.lnl = import ./modules/examples/lnl.nix;
    darwinModules.simple = import ./modules/examples/simple.nix;
    darwinModules.ofborg = import ./modules/examples/ofborg.nix;
    darwinModules.hydra = import ./modules/examples/hydra.nix;

    checks.x86_64-darwin.simple = (self.lib.darwinSystem {
      modules = [ self.darwinModules.simple ];
    }).system;

  };
}
