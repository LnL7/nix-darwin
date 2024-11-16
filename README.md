[<img src="https://daiderd.com/nix-darwin/images/nix-darwin.png" width="200px" alt="logo" />](https://github.com/LnL7/nix-darwin)

# nix-darwin

[![Test](https://github.com/LnL7/nix-darwin/actions/workflows/test.yml/badge.svg)](https://github.com/LnL7/nix-darwin/actions/workflows/test.yml)

Nix modules for darwin, `/etc/nixos/configuration.nix` for macOS.

This project aims to bring the convenience of a declarative system approach to macOS.
nix-darwin is built up around [Nixpkgs](https://github.com/NixOS/nixpkgs), quite similar to [NixOS](https://nixos.org/).

## Prerequisites

The only prerequisite is a Nix implementation, both Nix and Lix are supported.

As the official Nix installer does not include an automated uninstaller, and manual uninstallation on macOS is a complex process, we recommend using one of the following installers instead:

- The [Nix installer from Determinate Systems](https://github.com/DeterminateSystems/nix-installer?tab=readme-ov-file#determinate-nix-installer) is only recommended for use with flake-based setups. **Make sure you use it without the `--determinate` flag**. The `--determinate` flag installs the Determinate Nix distribution which does not work out of the box with nix-darwin.
* The [Lix installer](https://lix.systems/install/#on-any-other-linuxmacos-system) supports both flake-based and channel-based setups.

## Installing

If you wish to use nix-darwin with flakes, please refer to the [flakes](#flakes) section.

```bash
nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
./result/bin/darwin-installer
```

## Updating

The installer will configure a channel for this repository.

```bash
nix-channel --update darwin
darwin-rebuild changelog
```

> NOTE: If you are using Nix as a daemon service the channel for that will be owned by root.
> Use `sudo -i nix-channel --update darwin` instead.

## Uninstalling

To run the latest version of the uninstaller, you can run the following command:

```
nix --extra-experimental-features "nix-command flakes" run nix-darwin#darwin-uninstaller
```

If that command doesn't work for you, you can try the locally installed uninstaller:

```
darwin-uninstaller
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
}
```

## Flakes

nix-darwin aims for both non-flake and flake configurations to be well supported despite flakes being an experimental feature in Nix.

### Step 1. Creating `flake.nix`

<details>
<summary>Getting started from scratch</summary>
<p></p>

If you don't have an existing `configuration.nix`, you can run the following commands to generate a basic `flake.nix` inside `~/.config/nix-darwin`:

```bash
mkdir -p ~/.config/nix-darwin
cd ~/.config/nix-darwin
nix flake init -t nix-darwin
sed -i '' "s/simple/$(scutil --get LocalHostName)/" flake.nix
```

Make sure to change `nixpkgs.hostPlatform` to `aarch64-darwin` if you are using Apple Silicon.

</details>

<details>
<summary>Migrating from an existing configuration.nix</summary>
<p></p>

Add the following to `flake.nix` in the same folder as `configuration.nix`:

```nix
{
  description = "John's darwin system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }: {
    darwinConfigurations."Johns-MacBook" = nix-darwin.lib.darwinSystem {
      modules = [ ./configuration.nix ];
    };
  };
}
```

Make sure to replace `Johns-MacBook` with your hostname which you can find by running `scutil --get LocalHostName`.

Make sure to set `nixpkgs.hostPlatform` in your `configuration.nix` to either `x86_64-darwin` (Intel) or `aarch64-darwin` (Apple Silicon).

</details>

### Step 2. Installing `nix-darwin`

Instead of using `darwin-installer`, you can just run `darwin-rebuild switch` to install nix-darwin. As `darwin-rebuild` won't be installed in your `PATH` yet, you can use the following command:

```bash
nix run nix-darwin -- switch --flake ~/.config/nix-darwin
```

### Step 3. Using `nix-darwin`

After installing, you can run `darwin-rebuild` to apply changes to your system:

```bash
darwin-rebuild switch --flake ~/.config/nix-darwin
```

#### Using flake inputs

Inputs from the flake can also be passed into `darwinSystem`. These inputs are then
accessible as an argument `inputs`, similar to `pkgs` and `lib`, inside the configuration.

```nix
# in flake.nix
nix-darwin.lib.darwinSystem {
  modules = [ ./configuration.nix ];
  specialArgs = { inherit inputs; };
}
```

```nix
# in configuration.nix
{ pkgs, lib, inputs }:
# inputs.self, inputs.nix-darwin, and inputs.nixpkgs can be accessed here
```

## Documentation

Reference documentation of all the options is available [here](https://daiderd.com/nix-darwin/manual/index.html).
This can also be accessed locally using `man 5 configuration.nix`.

`darwin-help` will open a HTML version of the manpage in the default browser.

Furthermore there's `darwin-option` to introspect the settings of a system and its available options.
> NOTE: `darwin-option` is only available to non-flake installations.

```
$ darwin-option nix.linux-builder.enable
Value:
true

Default:
false

Example:
true

Description:
Whether to enable Linux builder.
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

Let's make Nix on macOS awesome!

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
- @LnL7 on twitter
