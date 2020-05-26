{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.system;
in

{
  options = {

    system.patches = mkOption {
      type = types.listOf types.path;
      default = [];
      example = literalExample ''
        [
          (pkgs.writeText "bashrc.patch" ''''
            --- a/etc/bashrc
            +++ b/etc/bashrc
            @@ -8,3 +8,5 @@
             shopt -s checkwinsize

             [ -r "/etc/bashrc_$TERM_PROGRAM" ] && . "/etc/bashrc_$TERM_PROGRAM"
            +
            +if test -e /etc/static/bashrc; then . /etc/static/bashrc; fi
          '''')
        ]
      '';
      description = ''
        Set of patches to apply to <filename>/</filename>.

        Useful for safely changing system files.  Unlike the etc module this
        won't remove or modify files with unexpected content.
      '';
    };

  };

  config = {

    system.build.patches = pkgs.runCommandNoCC "patches"
      { preferLocalBuild = true; }
      ''
        mkdir -p $out/patches
        cd $out/patches
        ${concatMapStringsSep "\n" (f: "ln -s '${f}' $(basename '${f}')") cfg.patches}
      '';

    system.activationScripts.patches.text = ''
      # Applying patches to /.
      echo "applying patches..." >&2

      f=$(readlink /run/current-system/patches)
      if ! test "$f" = ${config.system.build.patches}/patches; then
          for f in $(find /run/current-system/patches/ -type l); do
              patch --reverse --backup -d / -p1 < "$f" >/dev/null || true
          done

          ${concatMapStringsSep "\n" (f: "patch --forward --backup -d / -p1 < '${f}' || true") cfg.patches}
      fi
    '';

  };
}
