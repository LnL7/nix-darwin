{ config, options, lib, pkgs, ... }:

with lib;

let

  # Backport from Nixpkgs 23.05
  defaultOverridePriority =
    lib.modules.defaultOverridePriority or lib.modules.defaultPriority;

  # Backport from Nixpkgs 23.11
  mergeAttrDefinitionsWithPrio = lib.mergeAttrDefinitionsWithPrio or (opt:
    let
        # Inlined to avoid warning about using internal APIs 🥴
        pushDownProperties = cfg:
          if cfg._type or "" == "merge" then
            concatMap pushDownProperties cfg.contents
          else if cfg._type or "" == "if" then
            map (mapAttrs (n: v: mkIf cfg.condition v)) (pushDownProperties cfg.content)
          else if cfg._type or "" == "override" then
            map (mapAttrs (n: v: mkOverride cfg.priority v)) (pushDownProperties cfg.content)
          else # FIXME: handle mkOrder?
            [ cfg ];

        defsByAttr =
          lib.zipAttrs (
            lib.concatLists (
              lib.concatMap
                ({ value, ... }@def:
                  map
                    (lib.mapAttrsToList (k: value: { ${k} = def // { inherit value; }; }))
                    (pushDownProperties value)
                )
                opt.definitionsWithLocations
            )
          );
    in
      assert opt.type.name == "attrsOf" || opt.type.name == "lazyAttrsOf";
      lib.mapAttrs
            (k: v:
              let merging = lib.mergeDefinitions (opt.loc ++ [k]) opt.type.nestedTypes.elemType v;
              in {
                value = merging.mergedValue;
                inherit (merging.defsFinal') highestPrio;
              })
            defsByAttr);

  cfg = config.nixpkgs;
  opt = options.nixpkgs;

  isConfig = x:
    builtins.isAttrs x || lib.isFunction x;

  optCall = f: x:
    if lib.isFunction f
    then f x
    else f;

  mergeConfig = lhs_: rhs_:
    let
      lhs = optCall lhs_ { inherit pkgs; };
      rhs = optCall rhs_ { inherit pkgs; };
    in
    recursiveUpdate lhs rhs //
    optionalAttrs (lhs ? packageOverrides) {
      packageOverrides = pkgs:
        optCall lhs.packageOverrides pkgs //
        optCall (attrByPath [ "packageOverrides" ] { } rhs) pkgs;
    } //
    optionalAttrs (lhs ? perlPackageOverrides) {
      perlPackageOverrides = pkgs:
        optCall lhs.perlPackageOverrides pkgs //
        optCall (attrByPath [ "perlPackageOverrides" ] { } rhs) pkgs;
    };

  configType = mkOptionType {
    name = "nixpkgs-config";
    description = "nixpkgs config";
    check = x:
      let traceXIfNot = c:
            if c x then true
            else lib.traceSeqN 1 x false;
      in traceXIfNot isConfig;
    merge = args: foldr (def: mergeConfig def.value) {};
  };

  overlayType = mkOptionType {
    name = "nixpkgs-overlay";
    description = "nixpkgs overlay";
    check = lib.isFunction;
    merge = lib.mergeOneOption;
  };

  # TODO: Remove backwards compatibility hack when dropping
  # 22.11 support.
  pkgsType = types.pkgs or (types.uniq types.attrs) // {
    # This type is only used by itself, so let's elaborate the description a bit
    # for the purpose of documentation.
    description = "An evaluation of Nixpkgs; the top level attribute set of packages";
  };

  hasBuildPlatform = opt.buildPlatform.highestPrio < (mkOptionDefault {}).priority;
  hasHostPlatform = opt.hostPlatform.isDefined;
  hasPlatform = hasHostPlatform || hasBuildPlatform;

  # Context for messages
  hostPlatformLine = optionalString hasHostPlatform "${showOptionWithDefLocs opt.hostPlatform}";
  buildPlatformLine = optionalString hasBuildPlatform "${showOptionWithDefLocs opt.buildPlatform}";

  legacyOptionsDefined =
    optional (opt.system.highestPrio < (mkDefault {}).priority) opt.system
    ;

  defaultPkgs =
    if opt.hostPlatform.isDefined
    then
      let isCross = cfg.buildPlatform != cfg.hostPlatform;
          systemArgs =
            if isCross
            then {
              localSystem = cfg.buildPlatform;
              crossSystem = cfg.hostPlatform;
            }
            else {
              localSystem = cfg.hostPlatform;
            };
      in
      import cfg.source ({
        inherit (cfg) config overlays;
      } // systemArgs)
    else
      import cfg.source {
        inherit (cfg) config overlays;
        localSystem = { inherit (cfg) system; };
      };

  finalPkgs = if opt.pkgs.isDefined then cfg.pkgs.appendOverlays cfg.overlays else defaultPkgs;

in

{
  options.nixpkgs = {
    pkgs = mkOption {
      type = pkgsType;
      example = literalExpression "import <nixpkgs> {}";
      description = lib.mdDoc ''
        If set, the pkgs argument to all nix-darwin modules is the value of
        this option, extended with `nixpkgs.overlays`, if
        that is also set. The nix-darwin and Nixpkgs architectures must
        match. Any other options in `nixpkgs.*`, notably `config`,
        will be ignored.

        The default value imports the Nixpkgs from
        [](#opt-nixpkgs.source). The `config`, `overlays`, `localSystem`,
        and `crossSystem` are based on this option's siblings.

        This option can be used to increase
        the performance of evaluation, or to create packages that depend
        on a container that should be built with the exact same evaluation
        of Nixpkgs, for example. Applications like this should set
        their default value using `lib.mkDefault`, so
        user-provided configuration can override it without using
        `lib`.
      '';
    };

    config = mkOption {
      default = {};
      example = literalExpression
        ''
          { allowBroken = true; allowUnfree = true; }
        '';
      type = configType;
      description = lib.mdDoc ''
        The configuration of the Nix Packages collection.  (For
        details, see the Nixpkgs documentation.)  It allows you to set
        package configuration options.

        Ignored when `nixpkgs.pkgs` is set.
      '';
    };

    overlays = mkOption {
      default = [];
      example = literalExpression
        ''
          [
            (self: super: {
              openssh = super.openssh.override {
                hpnSupport = true;
                kerberos = self.libkrb5;
              };
            })
          ]
        '';
      type = types.listOf overlayType;
      description = lib.mdDoc ''
        List of overlays to use with the Nix Packages collection.
        (For details, see the Nixpkgs documentation.)  It allows
        you to override packages globally. Each function in the list
        takes as an argument the *original* Nixpkgs.
        The first argument should be used for finding dependencies, and
        the second should be used for overriding recipes.

        If `nixpkgs.pkgs` is set, overlays specified here
        will be applied after the overlays that were already present
        in `nixpkgs.pkgs`.
      '';
    };

    hostPlatform = mkOption {
      type = types.either types.str types.attrs; # TODO utilize lib.systems.parsedPlatform
      example = { system = "aarch64-darwin"; config = "aarch64-apple-darwin"; };
      # Make sure that the final value has all fields for sake of other modules
      # referring to this. TODO make `lib.systems` itself use the module system.
      apply = lib.systems.elaborate;
      description = lib.mdDoc ''
        Specifies the platform where the nix-darwin configuration will run.

        To cross-compile, set also `nixpkgs.buildPlatform`.

        Ignored when `nixpkgs.pkgs` is set.
      '';
    };

    buildPlatform = mkOption {
      type = types.either types.str types.attrs; # TODO utilize lib.systems.parsedPlatform
      default = cfg.hostPlatform;
      example = { system = "x86_64-darwin"; config = "x86_64-apple-darwin"; };
      # Make sure that the final value has all fields for sake of other modules
      # referring to this.
      apply = lib.systems.elaborate;
      defaultText = literalExpression
        ''config.nixpkgs.hostPlatform'';
      description = lib.mdDoc ''
        Specifies the platform on which nix-darwin should be built.
        By default, nix-darwin is built on the system where it runs, but you can
        change where it's built. Setting this option will cause nix-darwin to be
        cross-compiled.

        For instance, if you're doing distributed multi-platform deployment,
        or if you're building machines, you can set this to match your
        development system and/or build farm.

        Ignored when `nixpkgs.pkgs` is set.
      '';
    };

    system = mkOption {
      type = types.str;
      example = "x86_64-darwin";
      default =
        if opt.hostPlatform.isDefined
        then
          throw ''
            Neither ${opt.system} nor any other option in nixpkgs.* is meant
            to be read by modules and configurations.
            Use pkgs.stdenv.hostPlatform instead.
          ''
        else
          throw ''
            Neither ${opt.hostPlatform} nor the legacy option ${opt.system} has been set.
            The option ${opt.system} is still fully supported for interoperability,
            but will be deprecated in the future, so we recommend to set ${opt.hostPlatform}.
          '';
      defaultText = lib.literalMD ''
        Traditionally `builtins.currentSystem`, but unset when invoking nix-darwin through `lib.darwinSystem`.
      '';
      description = lib.mdDoc ''
        Specifies the Nix platform type on which nix-darwin should be built.
        It is better to specify `nixpkgs.hostPlatform` instead.

        Ignored when `nixpkgs.pkgs` or `nixpkgs.hostPlatform` is set.
      '';
    };

    # nix-darwin only

    source = mkOption {
      type = types.path;
      defaultText = literalMD ''
        `<nixpkgs>` or nix-darwin's `nixpkgs` flake input
      '';
      description = lib.mdDoc ''
        The path to import Nixpkgs from. If you're setting a custom
        [](#opt-nixpkgs.pkgs) or `_module.args.pkgs`, setting this
        to something with `rev` and `shortRev` attributes (such as a
        flake input or `builtins.fetchGit` result) will also set
        `system.nixpkgsRevision` and related options.
        (nix-darwin only)
      '';
    };

    constructedByUs = mkOption {
      type = types.bool;
      internal = true;
      description = ''
        Whether `pkgs` was constructed by this module. This is false when any of
        `nixpkgs.pkgs` or `_module.args.pkgs` is set. (nix-darwin only)
      '';
    };
  };

  config = {
    _module.args = {
      pkgs =
        # We explicitly set the default override priority, so that we do not need
        # to evaluate finalPkgs in case an override is placed on `_module.args.pkgs`.
        # After all, to determine a definition priority, we need to evaluate `._type`,
        # which is somewhat costly for Nixpkgs. With an explicit priority, we only
        # evaluate the wrapper to find out that the priority is lower, and then we
        # don't need to evaluate `finalPkgs`.
        lib.mkOverride defaultOverridePriority
          finalPkgs.__splicedPackages;
    };

    nixpkgs.constructedByUs =
      # We set it with default priority and it can not be merged, so if the
      # pkgs module argument has that priority, it's from us.
      (mergeAttrDefinitionsWithPrio options._module.args).pkgs.highestPrio
        == defaultOverridePriority
      # Although, if nixpkgs.pkgs is set, we did forward it, but we did not construct it.
        && !opt.pkgs.isDefined;

    assertions = [
      (
        let
          pkgsSystem = finalPkgs.stdenv.targetPlatform.system;
        in {
          assertion = cfg.constructedByUs -> !hasPlatform -> cfg.system == pkgsSystem;
          message = "The nix-darwin nixpkgs.pkgs option was set to a Nixpkgs invocation that compiles to target system ${pkgsSystem} but nix-darwin was configured for system ${darwinExpectedSystem} via nix-darwin option nixpkgs.system. The nix-darwin system settings must match the Nixpkgs target system.";
        }
      )
      {
        assertion = cfg.constructedByUs -> hasPlatform -> legacyOptionsDefined == [];
        message = ''
          Your system configures nixpkgs with the platform parameter${optionalString hasBuildPlatform "s"}:
          ${hostPlatformLine
          }${buildPlatformLine
          }
          However, it also defines the legacy options:
          ${concatMapStrings showOptionWithDefLocs legacyOptionsDefined}
          For a future proof system configuration, we recommend to remove
          the legacy definitions.
        '';
      }
    ];
  };
}
