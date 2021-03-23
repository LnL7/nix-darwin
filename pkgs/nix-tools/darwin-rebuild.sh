#! @shell@
set -e
set -o pipefail
export PATH=@path@:$PATH


showSyntax() {
  echo "darwin-rebuild [--help] {edit | switch | activate | build | check | changelog}" >&2
  echo "               [--list-generations] [{--profile-name | -p} name] [--rollback]" >&2
  echo "               [{--switch-generation | -G} generation] [--verbose...] [-v...]" >&2
  echo "               [-Q] [{--max-jobs | -j} number] [--cores number] [--dry-run]" >&1
  echo "               [--keep-going] [-k] [--keep-failed] [-K] [--fallback] [--show-trace]" >&2
  echo "               [-I path] [--option name value] [--arg name value] [--argstr name value]" >&2
  echo "               [--flake flake] [--update-input input flake] [--impure] [--recreate-lock-file]"
  echo "               [--no-update-lock-file] ..." >&2
  exec man darwin-rebuild
  exit 1
}

# Parse the command line.
origArgs=("$@")
extraBuildFlags=()
extraLockFlags=()
extraProfileFlags=()
profile=@profile@
action=
flake=

while [ $# -gt 0 ]; do
  i=$1; shift 1
  case $i in
    --help)
      showSyntax
      ;;
    edit|switch|activate|build|check|changelog)
      action=$i
      ;;
    --show-trace|--no-build-hook|--dry-run|--keep-going|-k|--keep-failed|-K|--verbose|-v|-vv|-vvv|-vvvv|-vvvvv|--fallback|-Q)
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
      extraBuildFlags+=("$i" "$j" "$k")
      ;;
    --flake)
      flake=$1
      shift 1
      ;;
    -L|-vL|--print-build-logs|--impure|--recreate-lock-file|--no-update-lock-file|--no-write-lock-file|--no-registries|--commit-lock-file)
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
    *)
      echo "$0: unknown option '$i'"
      exit 1
      ;;
  esac
done

if [ -z "$action" ]; then showSyntax; fi

flakeFlags=(--experimental-features 'nix-command flakes')

if [ -n "$flake" ]; then
    if [[ $flake =~ ^(.*)\#([^\#\"]*)$ ]]; then
       flake="${BASH_REMATCH[1]}"
       flakeAttr="${BASH_REMATCH[2]}"
    fi
    if [ -z "$flakeAttr" ]; then
      flakeAttr=$(hostname)
    fi
    flakeAttr=darwinConfigurations.${flakeAttr%.local}
fi

if [ -n "$flake" ]; then
    if nix "${flakeFlags[@]}" flake metadata --version &>/dev/null; then
        cmd=metadata
    else
        cmd=info
    fi

    flake=$(nix "${flakeFlags[@]}" flake "$cmd" --json "${extraBuildFlags[@]}" "${extraLockFlags[@]}" -- "$flake" | jq -r .url)
fi

if [ "$action" != build ] && [ -z "$flake" ]; then
  extraBuildFlags+=("--no-out-link")
fi

if [ "$action" = edit ]; then
  darwinConfig=$(nix-instantiate --find-file darwin-config)
  if [ -z "$flake" ]; then
    exec "${EDITOR:-vi}" "$darwinConfig"
  else
    exec nix "${flakeFlags[@]}" edit "${extraLockFlags[@]}" -- "$flake#$flakeAttr"
  fi
fi

if [ "$action" = switch ] || [ "$action" = build ] || [ "$action" = check ]; then
  echo "building the system configuration..." >&2
  if [ -z "$flake" ]; then
    systemConfig="$(nix-build '<darwin>' "${extraBuildFlags[@]}" -A system)"
  else
    nix "${flakeFlags[@]}" build "$flake#$flakeAttr.system" "${extraBuildFlags[@]}" "${extraLockFlags[@]}"
    systemConfig=$(readlink -f result)
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
  echo >&2
  echo "[1;1mCHANGELOG[0m" >&2
  echo >&2
  head -n 32 "$systemConfig/darwin-changes"
  echo >&2
fi

if [ "$action" = check ]; then
  export checkActivation=1
  "$systemConfig/activate-user"
fi
