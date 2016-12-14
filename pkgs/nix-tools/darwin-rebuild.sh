#! @shell@
set -e
set -o pipefail
export PATH=@path@:$PATH


showSyntax() {
    exec man darwin-rebuild
    exit 1
}

# Parse the command line.
origArgs=("$@")
action=

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

echo "building the system configuration..." >&2
if [ "$action" = switch -o "$action" = build ]; then
    systemConfig="$(nix-build '<darwin>' --no-out-link -A system)"
fi

if [ "$action" = build ]; then
    echo $systemConfig
fi


if [ "$action" = switch ]; then
    profileDir=$(dirname @profile@)

    if [ "$USER" != root -a ! -w $profileDir ]; then
        sudo nix-env -p @profile@ --set $systemConfig
    else
        nix-env -p @profile@ --set $systemConfig
    fi

    if [ "$USER" != root ]; then
      sudo $systemConfig/activate
    else
      $systemConfig/activate
    fi

    $systemConfig/activate-user
fi
