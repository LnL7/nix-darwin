[<img src="https://lnl7.github.io/nix-darwin/images/nix-darwin.png" width="200px" alt="logo" />](https://github.com/LnL7/nix-darwin)

# nix-darwin

![Test](https://github.com/LnL7/nix-darwin/workflows/Test/badge.svg)

Nix modules for darwin, `/etc/nixos/configuration.nix` for macOS.

This project aims to bring the convenience of a declarative system approach to macOS.
Nix-darwin is built up around [Nixpkgs](https://github.com/NixOS/nixpkgs), quite similar to [NixOS](https://nixos.org/).

## Install

To install nix-darwin, a working installation of [Nix](https://github.com/NixOS/nix#installation) is required.

```bash
nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
./result/bin/darwin-installer
```

> NOTE: the system activation scripts don't overwrite existing etc files, so files like `/etc/bashrc` and `/etc/zshrc` won't be
> updated by default. If you didn't use the installer or skipped some of the options you'll have to take care of this yourself.
> Either modify the existing file to source/import the one from `/etc/static` or remove it. Some examples:

- `mv /etc/bashrc /etc/bashrc.orig`
- `echo 'if test -e /etc/static/bashrc; then . /etc/static/bashrc; fi' | sudo tee -a /etc/bashrc`
- `echo 'if test -e /etc/static/bashrc; then . /etc/static/bashrc; fi' | tee -a ~/.bashrc`

## Updating

The installer will configure a channel for this repository.

```bash
nix-channel --update darwin
darwin-rebuild changelog
```

> NOTE: If you are using Nix as a daemon service the channel for that will be owned by root.
> Use `sudo -i nix-channel --update darwin` instead.

## Uninstalling

There's also an uninstaller if you don't like the project and want to
remove the configured files and services.

```bash
nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A uninstaller
./result/bin/darwin-uninstaller
```

## Example configuration

Configuration lives in `~/.nixpkgs/darwin-configuration.nix`. Check out
[modules/examples](https://github.com/LnL7/nix-darwin/tree/master/modules/examples) for some example configurations.

```nix
{ pkgs, ... }:
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    [ pkgs.vim
    ];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;
}
```

## Flakes (experimental)

There is also preliminary support for building your configuration using a [flake](https://nixos.wiki/wiki/Flakes).  This
is mostly based on the flake support that was added to NixOS.

A minimal example of using an existing configuration.nix:

```nix
{
  description = "John's darwin system";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-22.05-darwin";
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, darwin, nixpkgs }: {
    darwinConfigurations."Johns-MacBook" = darwin.lib.darwinSystem {
      system = "x86_64-darwin";
      modules = [ ./configuration.nix ];
    };
  };
}
```

Inputs from the flake can also be passed to `darwinSystem`, these inputs are then
accessible as an argument, similar to pkgs and lib inside the configuration.

```nix
darwin.lib.darwinSystem {
  system = "x86_64-darwin";
  modules = [ ... ];
  inputs = { inherit darwin dotfiles nixpkgs; };
}
```

Since the installer doesn't work with flakes out of the box yet, nix-darwin will need to
be bootstrapped using the installer or manually.  Afterwards the flake based
configuration can be built.  The `hostname(1)` of your system will be used to decide
which darwin configuration is applied if it's not specified explicitly in the flake ref.

```sh
nix build ~/.config/darwin\#darwinConfigurations.Johns-MacBook.system
./result/sw/bin/darwin-rebuild switch --flake ~/.config/darwin
```

## Manual Install

```bash
# Before 10.15 Catalina
sudo ln -s private/var/run /run
# After 10.15 Catalina
echo -e "run\tprivate/var/run" | sudo tee -a /etc/synthetic.conf
/System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -B
/System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t

# Configure the channel
nix-channel --add https://github.com/LnL7/nix-darwin/archive/master.tar.gz darwin
nix-channel --update
export NIX_PATH=darwin-config=$HOME/.nixpkgs/darwin-configuration.nix:$HOME/.nix-defexpr/channels:$NIX_PATH

# Or use a local git repository
git clone git@github.com:LnL7/nix-darwin.git ~/.nix-defexpr/darwin
export NIX_PATH=darwin=$HOME/.nix-defexpr/darwin:darwin-config=$HOME/.nixpkgs/darwin-configuration.nix:$NIX_PATH

cp ~/.nix-defexpr/darwin/modules/examples/simple.nix ~/.nixpkgs/darwin-configuration.nix

# you can also use this to rebootstrap nix-darwin in case
# darwin-rebuild is to old to activate the system.
$(nix-build '<darwin>' -A system --no-out-link)/sw/bin/darwin-rebuild build
$(nix-build '<darwin>' -A system --no-out-link)/sw/bin/darwin-rebuild switch

. /etc/static/bashrc
```

... or for `fish`:

```fish
(nix-build '<darwin>' -A system --no-out-link)/sw/bin/darwin-rebuild build
(nix-build '<darwin>' -A system --no-out-link)/sw/bin/darwin-rebuild switch
```

This will create and manage a system profile in `/run/current-system`, just like nixos.

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

## Documentation

Reference documentation of all the options is available [here](https://lnl7.github.io/nix-darwin/manual/index.html#sec-options).  
This can also be accessed locally using `man 5 configuration.nix`.

`darwin-help` will open a HTML version of the manpage in the default browser.

Furthermore there's `darwin-option` to introspect the settings of a system and its available options.
> NOTE: `darwin-option` is only available to non-flake installations.

```
$ darwin-option services.activate-system.enable
Value:
true

Default:
false

Example:
no example

Description:
Whether to activate system at boot time.
```

There's also a small wiki https://github.com/LnL7/nix-darwin/wiki about
specific topics, like macOS upgrades.

## Tests

There are basic tests that run sanity checks for some of the modules,
you can run them like this:

```bash
# run all tests
nix-build release.nix -A tests
# or just a subset
nix-build release.nix -A tests.environment-path
```

## Contributing

Let's make nix on darwin awesome!
Don't hesitate to contribute modules or open an issue.

To build your configuration with local changes you can run this. This
flag can also be used to override darwin-config or nixpkgs, for more
information on the `-I` flag look at the nix-build [manpage](https://nixos.org/manual/nix/stable/command-ref/nix-build.html).

```bash
darwin-rebuild switch -I darwin=.
```

If you're adding a module, please add yourself to `meta.maintainers`, for example

```nix
  meta.maintainers = [
    lib.maintainers.alice or "alice"
  ];

  options.services.alicebot = # ...
```

The `or` operator takes care of graceful degradation when `lib` from Nixpkgs
goes out of sync.

Also feel free to contact me if you have questions,
- Matrix - @daiderd:matrix.org, you can find me in [#macos:nixos.org](https://matrix.to/#/#macos:nixos.org)
- @lnl7 on twitter
