{ stdenv, writeScript, coreutils, nix }:

{
  darwin-option = writeScript "darwin-option" ''
    #! ${stdenv.shell}
    set -e

    echo "$0: not implemented" >&2
    exit 1
  '';

  darwin-rebuild = writeScript "darwin-rebuild" ''
    #! ${stdenv.shell}
    set -e

    showSyntax() {
        exec man darwin-rebuild
        exit 1
    }

    # Parse the command line.
    origArgs=("$@")
    action=
    profile=/nix/var/nix/profiles/system

    while [ "$#" -gt 0 ]; do
        i="$1"; shift 1
        case "$i" in
            --help)
              showSyntax
              ;;
            switch|build)
              action="$i"
              ;;
            *)
              echo "$0: unknown option \`$i'"
              exit 1
              ;;
        esac
    done

    if [ -z "$action" ]; then showSyntax; fi

    export PATH=${coreutils}/bin:$PATH

    echo "building the system configuration..." >&2
    if [ "$action" = switch -o "$action" = build ]; then
        systemConfig="$(nix-build '<darwin>' --no-out-link -A system)"
    fi

    if [ "$action" = switch ]; then
        sudo nix-env -p "$profile" --set $systemConfig
        sudo $systemConfig/activate
    fi
  '';
}
