# nix-darwin

Nix modules for darwin, `/etc/nixos/configuration.nix` for macOS.
This will creates and manages a system profile in `/run/current-system`, just like nixos.

The default `NIX_PATH` in nix-darwin will look for this repository in `~/.nix-defexpr/darwin` and for your configuration in `~/.nixpkgs/darwin-configuration.nix`.
If you want to change these you can set your own with `nix.nixPath = [ ];`.

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
setting up /etc...
setting up launchd services...
writing defaults...
$ 
```

```
$ darwin-option services.activate-system.enable                                                                                                                                            ~/src/nix-darwin
Value:
true

Default:
false

Example:
no example

Description:
Whether to activate system at boot time.
```

## Install

This will link the system profile to `/run/current-system`, you have to create `/run` or symlink it to `private/var/run`.
If you use a symlink you'll probably also want to add `services.activate-system.enable = true;` to your configuration.

> NOTE: the system activation scripts don't overrwrite existing etc files, etc files like `/etc/bashrc` won't be used by default.
Either modify the existing file to source/import the one from `/etc/static` or remove it.

```bash
# install nixpkgs version, this enables libsodium support (for signed binary caches)
# this is not required if you already upgraded nix at some point
nix-env -iA nixpkgs.nix

sudo ln -s private/var/run /run

git clone git@github.com:LnL7/nix-darwin.git ~/.nix-defexpr/darwin
cp ~/.nix-defexpr/darwin/modules/examples/simple.nix ~/.nixpkgs/darwin-configuration.nix

# bootstrap build using default nix.nixPath
export NIX_PATH=darwin=$HOME/.nix-defexpr/darwin:darwin-config=$HOME/.nixpkgs/darwin-configuration.nix:$NIX_PATH

# you can also use this to rebootstrap nix-darwin in case
# darwin-rebuild is to old to activate the system.
$(nix-build '<darwin>' -A system --no-out-link)/sw/bin/darwin-rebuild build
$(nix-build '<darwin>' -A system --no-out-link)/sw/bin/darwin-rebuild switch

. /etc/static/bashrc
```
