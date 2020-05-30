{ nixpkgs ? <nixpkgs>, configuration ? <darwin-config>, system ? builtins.currentSystem
, pkgs ? import nixpkgs { inherit system; }
, inputs ? {}
}:

let
  evalConfig = import ./eval-config.nix { inherit (pkgs) lib; };

  eval = evalConfig {
    inherit configuration;
    inputs = { inherit nixpkgs; } // inputs;
  };
in

eval // {
  installer = pkgs.callPackage ./pkgs/darwin-installer {};
  uninstaller = pkgs.callPackage ./pkgs/darwin-uninstaller {};
}
