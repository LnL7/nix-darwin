{ nixpkgs ? <nixpkgs>
, configuration ? <darwin-config>
, lib ? pkgs.lib
, pkgs ? import nixpkgs { inherit system; }
, system ? builtins.currentSystem
}:

let
  evalConfig = import ./eval-config.nix { inherit lib; };

  eval = evalConfig {
    inherit system;
    modules = [ configuration ];
    inputs = { inherit nixpkgs; };
  };

  # The source code of this repo needed by the [un]installers.
  nix-darwin = lib.cleanSource (
    lib.cleanSourceWith {
      # We explicitly specify a name here otherwise `cleanSource` will use the
      # basename of ./.  which might be different for different clones of this
      # repo leading to non-reproducible outputs.
      name = "nix-darwin";
      src = ./.;
    }
  );
in

eval // {
  installer = pkgs.callPackage ./pkgs/darwin-installer { inherit nix-darwin; };
  uninstaller = pkgs.callPackage ./pkgs/darwin-uninstaller { inherit nix-darwin; };
}
