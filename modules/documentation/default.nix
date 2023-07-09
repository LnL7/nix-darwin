{ config, lib, pkgs, baseModules, modules, ... }:

with lib;

let
  cfg = config.documentation;

  # To reference the regular configuration from inside the docs evaluation further down.
  # While not strictly necessary, this extra binding avoids accidental name capture in
  # the future.
  regularConfig = config;

  argsModule = {
    config._module.args = regularConfig._module.args // {
      modules = [ ];
    };
  };

  /* For the purpose of generating docs, evaluate options with each derivation
    in `pkgs` (recursively) replaced by a fake with path "\${pkgs.attribute.path}".
    It isn't perfect, but it seems to cover a vast majority of use cases.
    Caveat: even if the package is reached by a different means,
    the path above will be shown and not e.g. `${config.services.foo.package}`. */
  realManual = import ../../doc/manual {
    inherit pkgs config;
    version = config.system.darwinVersion;
    revision = config.system.darwinRevision;
    inherit (config.system) nixpkgsRevision;
    options =
      let
        scrubbedEval = evalModules {
          modules = baseModules ++ [ argsModule ];
          specialArgs = { pkgs = scrubDerivations "pkgs" pkgs; };
        };
        scrubDerivations = namePrefix: pkgSet: mapAttrs
          (name: value:
            let wholeName = "${namePrefix}.${name}"; in
            if isAttrs value then
              scrubDerivations wholeName value
              // (optionalAttrs (isDerivation value) { outPath = "\${${wholeName}}"; })
            else value
          )
          pkgSet;
      in scrubbedEval.options;
  };

  # TODO: Remove this when dropping 22.11 support.
  manual = realManual //
    lib.optionalAttrs (!pkgs.buildPackages ? nixos-render-docs) rec {
      optionsJSON = pkgs.writeTextFile {
        name = "options.json-stub";
        destination = "/share/doc/darwin/options.json";
        text = "{}";
      };
      manpages = pkgs.writeTextFile {
        name = "darwin-manpages-stub";
        destination = "/share/man/man5/configuration.nix.5";
        text = ''
          .TH "CONFIGURATION\&.NIX" "5" "01/01/1980" "Darwin" "Darwin Reference Pages"
          .SH "NAME"
          \fIconfiguration\&.nix\fP \- Darwin system configuration specification
          .SH "DESCRIPTION"
          .PP
          The nix\-darwin documentation now requires nixpkgs 23.05 to build.
        '';
      };
      manualHTML = pkgs.writeTextFile {
        name = "darwin-manual-html-stub";
        destination = "/share/doc/darwin/index.html";
        text = ''
          <!DOCTYPE html>
          <title>Darwin Configuration Options</title>
          The nix-darwin documentation now requires nixpkgs 23.05 to build.
        '';
      };
      manualHTMLIndex = "${manualHTML}/share/doc/darwin/index.html";
    };

  helpScript = pkgs.writeScriptBin "darwin-help"
    ''
      #! ${pkgs.stdenv.shell} -e
      open ${manual.manualHTMLIndex}
    '';
in

{
  options = {
    documentation.enable = mkOption {
      type = types.bool;
      default = true;
      description = lib.mdDoc ''
        Whether to install documentation of packages from
        {option}`environment.systemPackages` into the generated system path.

        See "Multiple-output packages" chapter in the nixpkgs manual for more info.
      '';
      # which is at ../../../doc/multiple-output.xml
    };

    documentation.man.enable = mkOption {
      type = types.bool;
      default = true;
      description = lib.mdDoc ''
        Whether to install manual pages and the {command}`man` command.
        This also includes "man" outputs.
      '';
    };

    documentation.info.enable = mkOption {
      type = types.bool;
      default = true;
      description = lib.mdDoc ''
        Whether to install info pages and the {command}`info` command.
        This also includes "info" outputs.
      '';
    };

    documentation.doc.enable = mkOption {
      type = types.bool;
      default = true;
      description = lib.mdDoc ''
        Whether to install documentation distributed in packages' `/share/doc`.
        Usually plain text and/or HTML.
        This also includes "doc" outputs.
      '';
    };
  };

  config = mkIf cfg.enable {

    programs.man.enable = cfg.man.enable;
    programs.info.enable = cfg.info.enable;

    environment.systemPackages = mkMerge [
      (mkIf cfg.man.enable [ manual.manpages ])
      (mkIf cfg.doc.enable [ manual.manualHTML helpScript ])
    ];

    system.build.manual = manual;

  };
}
