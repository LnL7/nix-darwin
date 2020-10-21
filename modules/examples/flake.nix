{
  description = "Example darwin system flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-20.09-darwin";
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, darwin, nixpkgs }:
  let
    configuration = { pkgs, ... }: {
      nix.package = pkgs.nixFlakes;

      # FIXME: for github actions, this shouldn't be in the example.
      services.nix-daemon.enable = true;
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake ./modules/examples#darwinConfigurations.simple.system \
    #       --override-input darwin .
    darwinConfigurations."simple" = darwin.lib.darwinSystem {
      modules = [ configuration darwin.darwinModules.simple ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."simple".pkgs;
  };
}
