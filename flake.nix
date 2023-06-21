{
  # WARNING this is very much still experimental.
  description = "A collection of darwin modules";

  # Temporary pin for Markdown documentation transition.
  inputs.nixpkgs.url = "nixpkgs/c1bca7fe84c646cfd4ebf3482c0e6317a0b13f22";

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

    checks.x86_64-darwin.simple = (self.lib.darwinSystem {
      system = "x86_64-darwin";
      modules = [ self.darwinModules.simple ];
    }).system;
  };
}
