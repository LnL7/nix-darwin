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

    system.build.etc = pkgs.runCommand "etc" {} ''
      mkdir -p $out/etc
      cd $out/etc
      ${concatMapStringsSep "\n" (attr: "mkdir -p $(dirname '${attr.target}')") etc}
      ${concatMapStringsSep "\n" (attr: "ln -s '${attr.source}' '${attr.target}'") etc}
    '';

    system.activationScripts.etc.text = ''
      # Set up the statically computed bits of /etc.
      echo "setting up /etc..."

      ln -sfn "$(readlink -f $systemConfig/etc)" /etc/static

      for link in $(ls /etc/static/); do
        if [ -e "/etc/$link" ]; then
          if [ ! -L "/etc/$link" ]; then
            echo "warning: not linking /etc/static/$link because /etc/$link exists, skipping..." >&2
          fi
        else
          ln -sfn "/etc/static/$link" "/etc/$link"
        fi
      done

      for link in $(find /etc/ -maxdepth 1 -type l); do
        if [[ "$(readlink $link)" == /etc/static/* ]]; then
          if [ ! -e "$(readlink -f $link)" ]; then
            rm $link
          fi
        fi
      done
    '';

  };
}
