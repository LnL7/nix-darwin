{ config, lib, pkgs, ... }:

with lib;

let

  text = import ../lib/write-text.nix {
    inherit lib;
    mkTextDerivation = name: text: pkgs.writeText "etc-${name}" text;
  };

  hasDir = path: length (splitString "/" path) > 1;

  etc = filter (f: f.enable) (attrValues config.environment.etc);
  etcCopy = filter (f: f.copy) (attrValues config.environment.etc);
  etcDirs = filter (attr: hasDir attr.target) (attrValues config.environment.etc);

in

{
  options = {

    environment.etc = mkOption {
      type = types.attrsOf (types.submodule text);
      default = { };
      description = lib.mdDoc ''
        Set of files that have to be linked in {file}`/etc`.
      '';
    };

  };

  config = {

    system.build.etc = pkgs.runCommand "etc"
      { preferLocalBuild = true; }
      ''
        mkdir -p $out/etc
        cd $out/etc
        ${concatMapStringsSep "\n" (attr: "mkdir -p $(dirname '${attr.target}')") etc}
        ${concatMapStringsSep "\n" (attr: "ln -s '${attr.source}' '${attr.target}'") etc}
        ${concatMapStringsSep "\n" (attr: "touch '${attr.target}'.copy") etcCopy}
      '';

    system.activationScripts.etc.text = ''
      # Set up the statically computed bits of /etc.
      echo "setting up /etc..." >&2

      declare -A etcSha256Hashes
      ${concatMapStringsSep "\n" (attr: "etcSha256Hashes['/etc/${attr.target}']='${concatStringsSep " " attr.knownSha256Hashes}'") etc}

      ln -sfn "$(readlink -f $systemConfig/etc)" /etc/static

      errorOccurred=false
      for etcStaticFile in $(find /etc/static/* -type l); do
        etcFile=/etc/''${etcStaticFile#/etc/static/}
        etcDir=''${etcFile%/*}
        if [ ! -e "$etcDir" ]; then
          mkdir -p "$etcDir"
        fi
        if [ -e "$etcStaticFile".copy ]; then
          cp "$etcStaticFile" "$etcFile"
          continue
        fi
        if [ -e "$etcFile" ]; then
          if [ "$(readlink "$etcFile")" != "$etcStaticFile" ]; then
            if ! grep -q /etc/static "$etcFile"; then
              etcFileSha256=''$(shasum -a256 "$etcFile")
              etcFileSha256=''${etcFileSha256%% *}
              for knownSha256Hash in ''${etcSha256Hashes["$etcFile"]}; do
                if [ "$etcFileSha256" = "$knownSha256Hash" ]; then
                  mv "$etcFile" "$etcFile.before-nix-darwin"
                  ln -s "$etcStaticFile" "$etcFile"
                  break
                else
                  knownSha256Hash=
                fi
              done

              if [ -z "$knownSha256Hash" ]; then
                echo "[1;31merror: not linking environment.etc.\"''${etcFile#/etc/}\" because $etcFile already exists, skipping...[0m" >&2
                echo "[1;31mexisting file has unknown content $etcFileSha256, move and activate again to apply[0m" >&2
                errorOccurred=true
              fi
            fi
          fi
        else
          ln -s "$etcStaticFile" "$etcFile"
        fi
      done

      if [ "$errorOccurred" != "false" ]; then
        exit 1
      fi

      for etcFile in $(find /etc/* -type l 2> /dev/null); do
        etcStaticFile="$(echo $etcFile | sed 's,/etc/,/etc/static/,')"
        etcStaticFile=/etc/static/''${etcFile#/etc/}
        if [ "$(readlink "$etcFile")" = "$etcStaticFile" -a ! -e "$(readlink -f "$etcFile")" ]; then
          rm "$etcFile"
        fi
      done
    '';

  };
}
