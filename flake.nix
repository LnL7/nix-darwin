{
  # WARNING this is very much still experimental.
  description = "A collection of darwin modules";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, flake-utils, nixpkgs }:
    let
      darwinSystems =
        builtins.filter
          (sys: builtins.isList (builtins.match "^[[:alnum:]_]+-darwin$" sys))
          flake-utils.lib.allSystems;

      portable = flake-utils.lib.eachSystem darwinSystems
        (system:
          let pkgs = import nixpkgs { inherit system; };

          in rec {
            defaultApp = apps.darwin-installer;

            apps = {
              darwin-installer = flake-utils.lib.mkApp {
                drv = pkgs.callPackage ./pkgs/darwin-installer/default.nix {
                  nix-darwin = self;
                };
              };

              darwin-uninstaller = flake-utils.lib.mkApp {
                drv = pkgs.callPackage ./pkgs/darwin-uninstaller/default.nix {
                  nix-darwin = self;
                };
              };
            };
          });

    in {
    inherit (portable) defaultApp apps;

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

    checks.x86_64-darwin.simple = (self.lib.darwinSystem {
      system = "x86_64-darwin";
      modules = [ self.darwinModules.simple ];
    }).system;

  };
}
