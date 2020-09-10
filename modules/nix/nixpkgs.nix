{ config, options, lib, pkgs, ... }:

with lib;

let
  isConfig = x:
    builtins.isAttrs x || builtins.isFunction x;

  optCall = f: x:
    if builtins.isFunction f
    then f x
    else f;

  mergeConfig = lhs_: rhs_:
    let
      lhs = optCall lhs_ { inherit pkgs; };
      rhs = optCall rhs_ { inherit pkgs; };
    in
    lhs // rhs //
    optionalAttrs (lhs ? packageOverrides) {
      packageOverrides = pkgs:
        optCall lhs.packageOverrides pkgs //
        optCall (attrByPath ["packageOverrides"] ({}) rhs) pkgs;
    } //
    optionalAttrs (lhs ? perlPackageOverrides) {
      perlPackageOverrides = pkgs:
        optCall lhs.perlPackageOverrides pkgs //
        optCall (attrByPath ["perlPackageOverrides"] ({}) rhs) pkgs;
    };

  configType = mkOptionType {
    name = "nixpkgs config";
    check = x:
      let traceXIfNot = c:
            if c x then true
            else lib.traceSeqN 1 x false;
      in traceXIfNot isConfig;
    merge = args: fold (def: mergeConfig def.value) {};
  };

  overlayType = mkOptionType {
    name = "nixpkgs-overlay";
    description = "nixpkgs overlay";
    check = builtins.isFunction;
    merge = lib.mergeOneOption;
  };

  pkgsType = mkOptionType {
    name = "nixpkgs";
    description = "An evaluation of Nixpkgs; the top level attribute set of packages";
    check = builtins.isAttrs;
  };

  defaultPkgs = import <nixpkgs> {
    inherit (config.nixpkgs) config overlays;
  };

  finalPkgs = if options.nixpkgs.pkgs.isDefined then config.nixpkgs.pkgs.appendOverlays config.nixpkgs.overlays else defaultPkgs;
in

{
  options = {
    nixpkgs.pkgs = mkOption {
      defaultText = ''
        import <nixpkgs> {
          inherit (config.nixpkgs) config overlays;
        };
      '';
      example = literalExample ''import <nixpkgs> {}'';
      type = pkgsType;
      description = ''
        If set, the pkgs argument to all NixOS modules is the value of
        this option, extended with nixpkgs.overlays, if that is also
        set. Any other options in nixpkgs.*, notably config, will be
        ignored. If unset, the pkgs argument to all nix-darwin modules
        is determined as shown in the default value for this option.
      '';
    };

    nixpkgs.config = mkOption {
      default = {};
      example = literalExample
        ''
          { firefox.enableGeckoMediaPlayer = true;
            packageOverrides = pkgs: {
              firefox60Pkgs = pkgs.firefox60Pkgs.override {
                enableOfficialBranding = true;
              };
            };
          }
        '';
      type = configType;
      description = ''
        The configuration of the Nix Packages collection.  (For
        details, see the Nixpkgs documentation.)  It allows you to set
        package configuration options, and to override packages
        globally through the <varname>packageOverrides</varname>
        option.  The latter is a function that takes as an argument
        the <emphasis>original</emphasis> Nixpkgs, and must evaluate
        to a set of new or overridden packages.
      '';
    };

    nixpkgs.overlays = mkOption {
      type = types.listOf overlayType;
      default = [];
      example = literalExample ''
        [ (self: super: {
            openssh = super.openssh.override {
              hpnSupport = true;
              withKerberos = true;
              kerberos = self.libkrb5;
            };
          };
        ) ]
      '';
      description = ''
        List of overlays to use with the Nix Packages collection.
        (For details, see the Nixpkgs documentation.)  It allows
        you to override packages globally. This is a function that
        takes as an argument the <emphasis>original</emphasis> Nixpkgs.
        The first argument should be used for finding dependencies, and
        the second should be used for overriding recipes.
      '';
    };

    nixpkgs.system = mkOption {
      type = types.str;
      example = "x86_64-darwin";
      description = ''
        Specifies the Nix platform type for which NixOS should be built.
        If unset, it defaults to the platform type of your host system.
        Specifying this option is useful when doing distributed
        multi-platform deployment, or when building virtual machines.
      '';
    };
  };

  config = {
    _module.args = {
      pkgs = finalPkgs;
    };
  };
}
