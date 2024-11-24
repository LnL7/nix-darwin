#! @shell@
set -e
set -o pipefail
export PATH=@path@:$PATH


showSyntax() {
  echo "darwin-rebuild [--help] {edit | switch | activate | build | check | changelog}" >&2
  echo "               [--list-generations] [{--profile-name | -p} name] [--rollback]" >&2
  echo "               [{--switch-generation | -G} generation] [--verbose...] [-v...]" >&2
  echo "               [-Q] [{--max-jobs | -j} number] [--cores number] [--dry-run]" >&2
  echo "               [--keep-going | -k] [--keep-failed | -K] [--fallback] [--show-trace]" >&2
  echo "               [--print-build-logs | -L] [--impure] [-I path]" >&2
  echo "               [--option name value] [--arg name value] [--argstr name value]" >&2
  echo "               [--no-flake | [--flake flake]" >&2
  echo "                             [--commit-lock-file] [--recreate-lock-file]" >&2
  echo "                             [--no-update-lock-file] [--no-write-lock-file]" >&2
  echo "                             [--override-input input flake] [--update-input input]" >&2
  echo "                             [--no-registries] [--offline] [--refresh]]" >&2
  echo "               [--substituters substituters-list] ..." >&2
  exit 1
}

sudo() {
  # REMOVEME when support for macOS 10.13 is dropped
  # macOS 10.13 does not support sudo --preserve-env so we make this conditional
  if command sudo --help | grep -- --preserve-env= >/dev/null; then
    # We use `env` before our command to ensure the preserved PATH gets checked
    # when trying to resolve the command to execute
    command sudo -H --preserve-env=PATH --preserve-env=SSH_CONNECTION env "$@"
  else
    command sudo -H "$@"
  fi
}

# Parse the command line.
origArgs=("$@")
extraMetadataFlags=()
extraBuildFlags=()
extraLockFlags=()
extraProfileFlags=()
profile=@profile@
action=
flake=
noFlake=

while [ $# -gt 0 ]; do
  i=$1; shift 1
  case $i in
    --help)
      showSyntax
      ;;
    edit|switch|activate|build|check|changelog)
      action=$i
      ;;
    --show-trace|--keep-going|--keep-failed|--verbose|-v|-vv|-vvv|-vvvv|-vvvvv|--fallback|--offline)
      extraMetadataFlags+=("$i")
      extraBuildFlags+=("$i")
      ;;
    --no-build-hook|--dry-run|-k|-K|-Q)
      extraBuildFlags+=("$i")
      ;;
    -j[0-9]*)
      extraBuildFlags+=("$i")
      ;;
    --max-jobs|-j|--cores|-I)
      if [ $# -lt 1 ]; then
        echo "$0: '$i' requires an argument"
        exit 1
      fi
      j=$1; shift 1
      extraBuildFlags+=("$i" "$j")
      ;;
    --arg|--argstr|--option)
      if [ $# -lt 2 ]; then
        echo "$0: '$i' requires two arguments"
        exit 1
      fi
      j=$1
      k=$2
      shift 2
      extraMetadataFlags+=("$i" "$j" "$k")
      extraBuildFlags+=("$i" "$j" "$k")
      ;;
    --flake)
      flake=$1
      shift 1
      ;;
    --no-flake)
      noFlake=1
      ;;
    -L|-vL|--print-build-logs|--impure|--recreate-lock-file|--no-update-lock-file|--no-write-lock-file|--no-registries|--commit-lock-file|--refresh)
      extraLockFlags+=("$i")
      ;;
    --update-input)
      j="$1"; shift 1
      extraLockFlags+=("$i" "$j")
      ;;
    --override-input)
      j="$1"; shift 1
      k="$1"; shift 1
      extraLockFlags+=("$i" "$j" "$k")
      ;;
    --list-generations)
      action="list"
      extraProfileFlags=("$i")
      ;;
    --rollback)
      action="rollback"
      extraProfileFlags=("$i")
      ;;
    --switch-generation|-G)
      action="rollback"
      if [ $# -lt 1 ]; then
        echo "$0: '$i' requires an argument"
        exit 1
      fi
      j=$1; shift 1
      extraProfileFlags=("$i" "$j")
      ;;
    --profile-name|-p)
      if [ -z "$1" ]; then
        echo "$0: '$i' requires an argument"
        exit 1
      fi
      if [ "$1" != system ]; then
        profile="/nix/var/nix/profiles/system-profiles/$1"
        mkdir -p -m 0755 "$(dirname "$profile")"
      fi
      shift 1
      ;;
    --substituters)
      if [ -z "$1" ]; then
        echo "$0: '$i' requires an argument"
        exit 1
      fi
      j=$1; shift 1
      extraMetadataFlags+=("$i" "$j")
      extraBuildFlags+=("$i" "$j")
      ;;
    *)
      echo "$0: unknown option '$i'"
      exit 1
      ;;
  esac
done

if [ -z "$action" ]; then showSyntax; fi

flakeFlags=(--extra-experimental-features 'nix-command flakes')

# Use /etc/nix-darwin/flake.nix if it exists. It can be a symlink to the
# actual flake.
if [[ -z $flake && -e /etc/nix-darwin/flake.nix && -z $noFlake ]]; then
  flake="$(dirname "$(readlink -f /etc/nix-darwin/flake.nix)")"
fi

# For convenience, use the hostname as the default configuration to
# build from the flake.
if [[ -n "$flake" ]]; then
    if [[ $flake =~ ^(.*)\#([^\#\"]*)$ ]]; then
       flake="${BASH_REMATCH[1]}"
       flakeAttr="${BASH_REMATCH[2]}"
    fi
    if [[ -z "$flakeAttr" ]]; then
      flakeAttr=$(scutil --get LocalHostName)
    fi
    flakeAttr=darwinConfigurations.${flakeAttr}
fi

if [ "$action" != build ]; then
  if [ -n "$flake" ]; then
    extraBuildFlags+=("--no-link")
  else
    extraBuildFlags+=("--no-out-link")
  fi
fi

if [ "$action" = edit ]; then
  darwinConfig=$(nix-instantiate --find-file darwin-config)
  if [ -z "$flake" ]; then
    exec "${EDITOR:-vi}" "$darwinConfig"
  else
    exec nix "${flakeFlags[@]}" edit "${extraLockFlags[@]}" -- "$flake#$flakeAttr"
  fi
fi

if [ "$action" = switch ] || [ "$action" = build ] || [ "$action" = check ] || [ "$action" = changelog ]; then
  echo "building the system configuration..." >&2
  if [ -z "$flake" ]; then
    systemConfig="$(nix-build '<darwin>' "${extraBuildFlags[@]}" -A system)"
  else
    systemConfig=$(nix "${flakeFlags[@]}" build --json \
      "${extraBuildFlags[@]}" "${extraLockFlags[@]}" \
      -- "$flake#$flakeAttr.system" \
      | jq -r '.[0].outputs.out')
  fi
fi

if [ "$action" = list ] || [ "$action" = rollback ]; then
  if [ "$USER" != root ] && [ ! -w $(dirname "$profile") ]; then
    sudo nix-env -p "$profile" "${extraProfileFlags[@]}"
  else
    nix-env -p "$profile" "${extraProfileFlags[@]}"
  fi
fi

if [ "$action" = rollback ]; then
  systemConfig="$(cat $profile/systemConfig)"
fi

if [ "$action" = activate ]; then
  systemConfig=$(readlink -f "${0%*/sw/bin/darwin-rebuild}")
fi

if [ -z "$systemConfig" ]; then exit 0; fi

if [ "$action" = switch ]; then
  if [ "$USER" != root ] && [ ! -w $(dirname "$profile") ]; then
    sudo nix-env -p "$profile" --set "$systemConfig"
  else
    nix-env -p "$profile" --set "$systemConfig"
  fi
fi

if [ "$action" = switch ] || [ "$action" = activate ] || [ "$action" = rollback ]; then
  "$systemConfig/activate-user"

  if [ "$USER" != root ]; then
    sudo "$systemConfig/activate"
  else
    "$systemConfig/activate"
  fi
fi

if [ "$action" = changelog ]; then
  ${PAGER:-less} -- "$systemConfig/darwin-changes"
fi

if [ "$action" = check ]; then
  export checkActivation=1
  "$systemConfig/activate-user"
fi
