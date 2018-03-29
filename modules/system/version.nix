{ options, config, lib, pkgs, ... }:

with lib;

let
  cfg = config.system;

  defaultStateVersion = options.system.stateVersion.default;

  gitCommitId = lib.substring 0 7 (commitIdFromGitRepo gitRepo);
  gitRepo = "${toString pkgs.path}/.git/";
  releaseFile = "${toString pkgs.path}/.version";
  revisionFile = "${toString pkgs.path}/.git-revision";
  suffixFile = "${toString pkgs.path}/.version-suffix";
in

{
  options = {
    system.stateVersion = mkOption {
      type = types.int;
      default = 3;
      description = ''
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
      default = cfg.nixpkgsVersion;
      description = "Label to be used in the names of generated outputs.";
    };

    system.nixpkgsRelease = mkOption {
      readOnly = true;
      type = types.str;
      default = fileContents releaseFile;
      description = "The nixpkgs release (e.g. <literal>16.03</literal>).";
    };

    system.nixpkgsVersion = mkOption {
      internal = true;
      type = types.str;
      description = "The full nixpkgs version (e.g. <literal>16.03.1160.f2d4ee1</literal>).";
    };

    system.nixpkgsVersionSuffix = mkOption {
      internal = true;
      type = types.str;
      default = "pre-git";
      description = "The nixpkgs version suffix (e.g. <literal>1160.f2d4ee1</literal>).";
    };

    system.nixpkgsRevision = mkOption {
      internal = true;
      type = types.str;
      default = "master";
      description = "The nixpkgs git revision from which this configuration was built.";
    };
  };

  config = {

    # These defaults are set here rather than up there so that
    # changing them would not rebuild the manual
    system.nixpkgsVersion = mkDefault (cfg.nixpkgsRelease + cfg.nixpkgsVersionSuffix);
    system.nixpkgsRevision = mkIf (builtins.pathExists gitRepo) (mkDefault gitCommitId);
    system.nixpkgsVersionSuffix = mkIf (builtins.pathExists gitRepo) (mkDefault (".git." + gitCommitId));

    assertions = [ { assertion = cfg.stateVersion <= defaultStateVersion; message = "system.stateVersion = ${toString cfg.stateVersion}; is not a valid value"; } ];

  };
}
