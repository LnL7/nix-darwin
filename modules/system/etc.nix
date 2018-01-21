{ config, lib, pkgs, ... }:

with lib;

let

  text = import ../lib/write-text.nix {
    inherit lib;
    mkTextDerivation = name: text: pkgs.writeText "etc-${name}" text;
  };

  hasDir = path: length (splitString "/" path) > 1;

  etc = filter (f: f.enable) (attrValues config.environment.etc);
  etcDirs = filter (attr: hasDir attr.target) (attrValues config.environment.etc);

in

{
  options = {

    environment.etc = mkOption {
      type = types.loaOf (types.submodule text);
      default = {};
      description = ''
        Set of files that have to be linked in <filename>/etc</filename>.
      '';
    };

  };

  config = {

    system.build.etc = pkgs.runCommandNoCC "etc"
      { preferLocalBuild = true; }
      ''
        mkdir -p $out/etc
        cd $out/etc
        ${concatMapStringsSep "\n" (attr: "mkdir -p $(dirname '${attr.target}')") etc}
        ${concatMapStringsSep "\n" (attr: "ln -s '${attr.source}' '${attr.target}'") etc}
      '';

    system.activationScripts.etc.text = ''
      # Set up the statically computed bits of /etc.
      echo "setting up /etc..." >&2

      ln -sfn "$(readlink -f $systemConfig/etc)" /etc/static

      for f in $(find /etc/static/* -type l); do
        l=/etc/''${f#/etc/static/}
        d=''${l%/*}
        if [ ! -e "$d" ]; then
          mkdir -p "$d"
        fi
        if [ -e "$l" ]; then
          if [ "$(readlink $l)" != "$f" ]; then
            if ! grep -q /etc/static "$l"; then
              echo "[1;31mwarning: not linking environment.etc.\"''${l#/etc/}\" because $l exists, skipping...[0m" >&2
            fi
          fi
        else
          ln -s "$f" "$l"
        fi
      done

      for l in $(find /etc/* -type l 2> /dev/null); do
        f="$(echo $l | sed 's,/etc/,/etc/static/,')"
        f=/etc/static/''${l#/etc/}
        if [ "$(readlink $l)" = "$f" -a ! -e "$(readlink -f $l)" ]; then
          rm "$l"
        fi
      done
    '';

  };
}
