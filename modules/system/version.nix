{ options, config, lib, ... }:

with lib;

let
  cfg = config.system;

  defaultStateVersion = options.system.stateVersion.default;

  # Based on `lib.trivial.revisionWithDefault` from nixpkgs.
  gitRevision = path:
    if pathIsGitRepo "${path}/.git"
    then commitIdFromGitRepo "${path}/.git"
    else if pathExists "${path}/.git-revision"
    then fileContents "${path}/.git-revision"
    else null;

  nixpkgsSrc = config.nixpkgs.source;

  # If `nixpkgs.constructedByUs` is true, then Nixpkgs was imported from
  # `nixpkgs.source` and we can use revision information (flake input,
  # `builtins.fetchGit`, etc.) from it. Otherwise `pkgs` could be
  # anything and we can't reliably determine exact version information,
  # but if the configuration explicitly sets `nixpkgs.source` we
  # trust it.
  useSourceRevision =
    (config.nixpkgs.constructedByUs
      || options.nixpkgs.source.highestPrio < (lib.mkDefault {}).priority)
    && isAttrs nixpkgsSrc
    && (nixpkgsSrc._type or null == "flake"
      || isString (nixpkgsSrc.rev or null));
in

{
  options = {
    system.stateVersion = mkOption {
      type = types.int;
      default = 4;
      description = lib.mdDoc ''
        Every once in a while, a new NixOS release may change
        configuration defaults in a way incompatible with stateful
        data. For instance, if the default version of PostgreSQL
        changes, the new version will probably be unable to read your
        existing databases. To prevent such breakage, you can set the
        value of this option to the NixOS release with which you want
        to be compatible. The effect is that NixOS will option
        defaults corresponding to the specified release (such as using
        an older version of PostgreSQL).
      '';
    };

    system.darwinLabel = mkOption {
      type = types.str;
      description = lib.mdDoc "Label to be used in the names of generated outputs.";
    };

    system.darwinVersion = mkOption {
      internal = true;
      type = types.str;
      default = "darwin${toString cfg.stateVersion}${cfg.darwinVersionSuffix}";
      description = lib.mdDoc "The full darwin version (e.g. `darwin4.2abdb5a`).";
    };

    system.darwinVersionSuffix = mkOption {
      internal = true;
      type = types.str;
      default = if cfg.darwinRevision != null
        then ".${substring 0 7 cfg.darwinRevision}"
        else "";
      description = lib.mdDoc "The short darwin version suffix (e.g. `.2abdb5a`).";
    };

    system.darwinRevision = mkOption {
      internal = true;
      type = types.nullOr types.str;
      default = gitRevision (toString ../..);
      description = lib.mdDoc "The darwin git revision from which this configuration was built.";
    };

    system.nixpkgsRelease = mkOption {
      readOnly = true;
      type = types.str;
      default = lib.trivial.release;
      description = lib.mdDoc "The nixpkgs release (e.g. `16.03`).";
    };

    system.nixpkgsVersion = mkOption {
      internal = true;
      type = types.str;
      default = cfg.nixpkgsRelease + cfg.nixpkgsVersionSuffix;
      description = lib.mdDoc "The full nixpkgs version (e.g. `16.03.1160.f2d4ee1`).";
    };

    system.nixpkgsVersionSuffix = mkOption {
      internal = true;
      type = types.str;
      default = if useSourceRevision
        then ".${lib.substring 0 8 (nixpkgsSrc.lastModifiedDate or nixpkgsSrc.lastModified or "19700101")}.${nixpkgsSrc.shortRev or "dirty"}"
        else lib.trivial.versionSuffix;
      description = lib.mdDoc "The short nixpkgs version suffix (e.g. `.1160.f2d4ee1`).";
    };

    system.nixpkgsRevision = mkOption {
      internal = true;
      type = types.nullOr types.str;
      default = if useSourceRevision && nixpkgsSrc ? rev
        then nixpkgsSrc.rev
        else lib.trivial.revisionWithDefault null;
      description = lib.mdDoc "The nixpkgs git revision from which this configuration was built.";
    };

    system.configurationRevision = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = lib.mdDoc "The Git revision of the top-level flake from which this configuration was built.";
    };
  };

  config = {
    # This default is set here rather than up there so that the options
    # documentation is not reprocessed on every commit
    system.darwinLabel = mkDefault "${cfg.nixpkgsVersion}+${cfg.darwinVersion}";

    assertions = [ {
      assertion = cfg.stateVersion <= defaultStateVersion;
      message = "system.stateVersion = ${toString cfg.stateVersion}; is not a valid value";
    } ];
  };
}
