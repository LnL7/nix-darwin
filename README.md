# nix-darwin

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

This will link the system profile to `/run/current-system`, you have to create `/run` or symlink it to `private/var/run`.
If you use a symlink you'll probably also want to add `services.activate-system.enable = true;` to your configuration.

> NOTE: the system activation scripts don't overrwrite existing etc files, etc files like `/etc/bashrc` won't be used by default.
Either modify the existing file to source/import the one from `/etc/static` or remove the file.

```bash
git clone git@github.com:LnL7/nix-darwin.git
nix-build -I darwin=$PWD/nix-darwin -I darwin-config=$PWD/config.nix '<darwin>' -A system
source result/etc/bashrc

result/sw/bin/darwin-rebuild build
result/sw/bin/darwin-rebuild switch
```

## Example configuration

Checkout [modules/examples](https://github.com/LnL7/nix-darwin/tree/master/modules/examples) for some example configurations.
```nix

{ config, lib, pkgs, ... }:
{

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    [ pkgs.nix-repl
    ];

  programs.bash.enable = true;
  programs.bash.interactiveShellInit = ''
    # Edit the NIX_PATH entries below or put the nix-darwin repository in
    # ~/.nix-defexpr/darwin and your configuration in ~/.nixpkgs/darwin-config.nix

    export NIX_PATH=darwin=$HOME/.nix-defexpr/darwin:darwin-config=$HOME/.nixpkgs/darwin-config.nix:$NIX_PATH
  '';

  services.activate-system.enable = true;

}
```
