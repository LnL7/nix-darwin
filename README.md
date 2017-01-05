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
sudo ln -s private/var/run /run

git clone git@github.com:LnL7/nix-darwin.git ~/.nix-defexpr/darwin
cp ~/.nix-defexpr/darwin/modules/examples/simple.nix ~/.nixpkgs/darwin-configuration.nix

# bootstrap build using default nix.nixPath
export NIX_PATH=darwin=$HOME/.nix-defexpr/darwin:darwin-config=$HOME/.nixpkgs/darwin-configuration.nix:$NIX_PATH

# you can also use this to rebootstrap nix-darwin in case
# darwin-rebuild is to old to activate the system.
$(nix-build '<darwin>' -A system --no-out-link)/sw/bin/darwin-rebuild build
$(nix-build '<darwin>' -A system --no-out-link)/sw/bin/darwin-rebuild switch
```

## Example configuration

Checkout [modules/examples](https://github.com/LnL7/nix-darwin/tree/master/modules/examples) for some example configurations.

```nix
{ pkgs, ... }:
{

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    [ pkgs.nix-repl
    ];

  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.bash.enable = true;

  # Recreate /run/current-system symlink after boot.
  services.activate-system.enable = true;

}
```

## Modules

### system.defaults

A set of [modules](https://github.com/LnL7/nix-darwin/tree/master/modules/system/defaults) to manage macOS settings.

```nix
{
  system.defaults.dock.autohide = true;
  system.defaults.dock.orientation = "left";
  system.defaults.dock.showhidden = true;
}
```

> NOTE: you have to restart the dock in order for these changes to apply. `killall Dock`

### environment.etc

Set of files to be linked in `/etc`, this won't overwrite any existing files.
Either modify the existing file to source/import the one from `/etc/static` or remove it.

```nix
{
  environment.etc."foorc".text = ''
    export FOO=1

    if test -f /etc/foorc.local; then
      . /etc/foorc.local
    fi
  '';

  # Global user configuration, symlink these to the appropriate file:
  # $ ln -s /etc/static/per-user/lnl/gitconfig ~/.gitconfig
  environment.etc."per-user/lnl/gitconfig" = ''
    [include]
      path = .gitconfig.local

    [color]
      ui = auto
  '';
}
```

### launchd.daemons

Definition of launchd agents/daemons. The [serviceConfig](https://github.com/LnL7/nix-darwin/blob/master/modules/launchd/launchd.nix) options are used to generate the launchd plist file.

```nix
{
  launchd.daemons.foo = {
    serviceConfig.ProgramArguments = [ "/usr/bin/touch" "/tmp/foo.lock" ];
    serviceConfig.RunAtLoad = true;
  };
}
```

### services

A set of modules for predefined services, these generate the appropriate launchd daemons for you.

```nix
{
  services.nix-daemon.enable = true;
  services.nix-daemon.tempDir = "/nix/tmp";
}
```

### programs

A set of modules to manage configuration of certain programs.

```nix
{ pkgs, ... }:

{
  environment.shellAliases.ls = "${pkgs.coreutils}/bin/ls";

  programs.bash.enable = true;

  programs.vim.enable = true;
  programs.vim.enableSensible = true;
}
```

### nixpkgs.config

This attribute set is used as nixpkgs configuration when using nix-darwin.

```nix
{
  environment.systemPackages =
    [ # Use vim_configurable from packageOverrides
      lnl.vim
    ];

  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.packageOverrides = pkgs: {
    lnl.vim = pkgs.vim_configurable.customize {
      name = "vim";
      vimrcConfig.customRC = ''
        set nocompatible
        filetype plugin indent on
        syntax on
      '';
    };
  };
}
```
