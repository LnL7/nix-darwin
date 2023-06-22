{
  # WARNING this is very much still experimental.
  description = "A collection of darwin modules";

  outputs = { self, nixpkgs }: {
    lib = {
      # TODO handle multiple architectures.
      evalConfig = import ./eval-config.nix { inherit (nixpkgs) lib; };

      darwinSystem =
        { modules, inputs ? { }
        , system ? throw "darwin.lib.darwinSystem now requires 'system' to be passed explicitly"
        , ...
        }@args:
        self.lib.evalConfig (args // {
          inherit system;
          inputs = { inherit nixpkgs; darwin = self; } // inputs;
          modules = modules ++ [ self.darwinModules.flakeOverrides ];
        });
    };

    darwinModules.flakeOverrides = ./modules/system/flake-overrides.nix;
    darwinModules.hydra = ./modules/examples/hydra.nix;
    darwinModules.lnl = ./modules/examples/lnl.nix;
    darwinModules.ofborg = ./modules/examples/ofborg.nix;
    darwinModules.simple = ./modules/examples/simple.nix;

    templates.default = {
      path = ./modules/examples/flake;
      description = "nix flake init -t nix-darwin";
    };

    checks = nixpkgs.lib.genAttrs ["aarch64-darwin" "x86_64-darwin"] (system: let
      simple = self.lib.darwinSystem {
        inherit system;
        modules = [ self.darwinModules.simple ];
      };
    in {
      simple = simple.system;

      inherit (simple.config.system.build.manual)
        optionsJSON
        manualHTML
        manpages;
    });
  };
}
