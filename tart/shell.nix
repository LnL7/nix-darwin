{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/6cee3b5893090b0f5f0a06b4cf42ca4e60e5d222.tar.gz") {
  config.allowUnfree = true;
} }:

pkgs.mkShell {
  nativeBuildInputs = [
    pkgs.tart
    pkgs.vncdo
    pkgs.bashInteractive
  ];

  shellHook = ''
    export TART_HOME=/Users/enzime/Code/nix-darwin/tart/darwin-vm
  '';
}
