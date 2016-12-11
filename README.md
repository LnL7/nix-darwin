# nixdarwin-rebuild

Nix modules for darwin.

```
$ darwin-rebuild switch
building the system configuration...
these derivations will be built:
  /nix/store/vfad6xgjzr56jcs051cg6vzch4dby92y-etc-zprofile.drv
  /nix/store/cbmkscxsz0k02ynaph5xaxm1aql0p3vq-etc.drv
  /nix/store/r5fpn177jhc16f8iyzk12gcw4pivzpbw-nixdarwin-system-16.09.drv
building path(s) ‘/nix/store/wlq89shja597ip7mrmjv7yzk2lwyh8n0-etc-zprofile’
building path(s) ‘/nix/store/m8kcm1pa5j570h3indp71a439wsh9lzq-etc’
building path(s) ‘/nix/store/l735ffcdvcvy60i8pqf6v00vx7lnm6mz-nixdarwin-system-16.09’
writing defaults...
setting up /etc...
warning: /etc/zprofile is a file, skipping...
warning: /etc/zshrc is a file, skipping...
setting up launchd services...
$ 
```

## Install

> NOTE: the system activation scripts don't overrwrite existing etc files, etc files like `/etc/bashrc` won't be used by default.
Either modify the existing file to source/import the one from `/etc/static` or remove the file.

```bash
git clone git@github.com:LnL7/nix-darwin.git
export NIX_PATH=darwin=$PWD/nix-darwin:darwin-config=$PWD/config.nix:$NIX_PATH
nix-build '<darwin>' -A system
result/bin/darwin-rebuild build
result/bin/darwin-rebuild switch
```

## Example configuration

```nix
{ config, lib, pkgs, ... }:
{

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    [ # Include nix-tools
      config.system.build.nix

      pkgs.nix-repl
    ];

  environment.etc."bashrc".text = ''
    # /etc/bashrc: DO NOT EDIT -- this file has been generated automatically.
    # This file is read for interactive shells.

    # Only execute this file once per shell.
    if [ -n "$__ETC_BASHRC_SOURCED" -o -n "$NOSYSBASHRC" ]; then return; fi
    __ETC_BASHRC_SOURCED=1

    export NIX_PATH=nixpkgs=$HOME/.nix-defexpr/nixpkgs:darwin=$HOME/.nix-defexpr/darwin:darwin-config=$HOME/.nixpkgs/darwin-config.nix:$NIX_PATH

    export PATH=${config.environment.systemPath}''${PATH:+:$PATH}

    ${config.system.build.setEnvironment}
    ${config.system.build.setAliases}
  '';
}
```
