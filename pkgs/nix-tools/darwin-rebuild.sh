#! @shell@
set -e
set -o pipefail
export PATH=@path@:$PATH


showSyntax() {
  echo "darwin-rebuild [--help] {build | switch} [{--profile-name | -p} name]" >&2
  echo "               [--verbose...] [-v...] [-Q] [{--max-jobs | -j} number] [--cores number]" >&2
  echo "               [--dry-run] [--keep-going] [-k] [--keep-failed] [-K] [--fallback] [--show-trace] [-I path]" >&2
  echo "               [--option name value] [--arg name value] [--argstr name value]" >&2
  exec man darwin-rebuild
  exit 1
}

# Parse the command line.
origArgs=("$@")
extraBuildFlags=()
profile=@profile@
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
    --show-trace|--no-build-hook|--dry-run|--keep-going|-k|--keep-failed|-K|--verbose|-v|-vv|-vvv|-vvvv|-vvvvv|--fallback|-Q)
      extraBuildFlags+=("$i")
      ;;
    --max-jobs|-j|--cores|-I)
      if [ -z "$1" ]; then
        echo "$0: ‘$i’ requires an argument"
        exit 1
      fi
      j="$1"; shift 1
      extraBuildFlags+=("$i" "$j")
      ;;
    --arg|--argstr|--option)
      if [ -z "$1" -o -z "$2" ]; then
        echo "$0: ‘$i’ requires two arguments"
        exit 1
      fi
      j="$1"; shift 1
      k="$1"; shift 1
      extraBuildFlags+=("$i" "$j" "$k")
      ;;
    --profile-name|-p)
      if [ -z "$1" ]; then
        echo "$0: ‘--profile-name’ requires an argument"
        exit 1
      fi
      if [ "$1" != system ]; then
        profile="/nix/var/nix/profiles/system-profiles/$1"
        mkdir -p -m 0755 "$(dirname "$profile")"
      fi
      shift 1
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
  systemConfig="$(nix-build '<darwin>' ${extraBuildFlags[@]} --no-out-link -A system)"
fi

if [ -z "$systemConfig" ]; then exit 0; fi

if [ "$action" = build ]; then
  echo $systemConfig
fi


if [ "$action" = switch ]; then
  if [ "$USER" != root -a ! -w $(dirname "$profile") ]; then
    sudo nix-env -p $profile --set $systemConfig
  else
    nix-env -p $profile --set $systemConfig
  fi

  if [ "$USER" != root ]; then
    sudo $systemConfig/activate
  else
    $systemConfig/activate
  fi

  $systemConfig/activate-user
fi
