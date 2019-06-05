{ options, config, lib, pkgs, ... }:

with lib;

let
  cfg = config.system;

  defaultStateVersion = options.system.stateVersion.default;

  parseGit = path:
    if pathExists "${path}/.git/" then rec {
      rev = commitIdFromGitRepo "${path}/.git/";
      shortRev = substring 0 7 rev;
    }
    else if pathExists "${path}/.git-revision" then rec {
      rev = fileContents "${path}/.git-revision";
      shortRev = substring 0 7 rev;
    }
    else {
      shortRev = "0000000";
    };

  darwin = parseGit (toString ../..);
  nixpkgs = parseGit (toString pkgs.path);

  releaseFile = "${toString pkgs.path}/.version";
  suffixFile = "${toString pkgs.path}/.version-suffix";

  nixpkgsSuffix = if pathExists suffixFile then fileContents suffixFile
                  else ".git." + nixpkgs.shortRev;
in

{
  options = {
    system.stateVersion = mkOption {
      type = types.int;
      default = 4;
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
      description = "Label to be used in the names of generated outputs.";
    };

    system.darwinVersion = mkOption {
      internal = true;
      type = types.str;
      description = "The full darwin version (e.g. <literal>darwin4.master</literal>).";
    };

    system.darwinRevision = mkOption {
      internal = true;
      type = types.str;
      default = "master";
      description = "The darwin git revision from which this configuration was built.";
    };

    system.nixpkgsRelease = mkOption {
      readOnly = true;
      type = types.str;
      description = "The nixpkgs release (e.g. <literal>16.03</literal>).";
    };

    system.nixpkgsVersion = mkOption {
      internal = true;
      type = types.str;
      description = "The full nixpkgs version (e.g. <literal>16.03.1160.f2d4ee1</literal>).";
    };

    system.nixpkgsRevision = mkOption {
      internal = true;
      type = types.str;
      description = "The nixpkgs git revision from which this configuration was built.";
    };
  };

  config = {

    # These defaults are set here rather than up there so that
    # changing them would not rebuild the manual
    system.darwinLabel = "${cfg.nixpkgsVersion}+${cfg.darwinVersion}";
    system.darwinVersion = "darwin" + toString cfg.stateVersion + "." + darwin.shortRev;
    system.darwinRevision = mkIf (darwin ? rev) (mkDefault darwin.rev);

    system.nixpkgsVersion = mkDefault (cfg.nixpkgsRelease + nixpkgsSuffix);
    system.nixpkgsRelease = mkDefault (fileContents releaseFile);
    system.nixpkgsRevision = mkIf (nixpkgs ? rev) (mkDefault nixpkgs.rev);

    assertions = [ { assertion = cfg.stateVersion <= defaultStateVersion; message = "system.stateVersion = ${toString cfg.stateVersion}; is not a valid value"; } ];

  };
}
