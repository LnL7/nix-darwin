{ nixpkgs ? <nixpkgs>
, configuration ? <darwin-config>
, system ? builtins.currentSystem
, pkgs ? import nixpkgs { inherit system; }
, lib ? pkgs.lib
}:

let
  eval = import ./eval-config.nix {
    inherit lib;
    modules = [
      configuration
      { nixpkgs.source = lib.mkDefault nixpkgs; }
    ] ++ lib.optional (system != null) {
      nixpkgs.system = lib.mkDefault system;
    };
  };
in
eval // {
  uninstaller = pkgs.callPackage ./pkgs/darwin-uninstaller { };
}
