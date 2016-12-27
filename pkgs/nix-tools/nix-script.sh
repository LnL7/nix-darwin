#! @shell@
set -e
set -o pipefail


showUsage() {
  echo "usage: nix [--version] [--help]" >&2
  echo "           <action> [<args>] [-- <expr>]" >&2
  echo "actions:   {i | instantiate | e | eval | drv}" >&2
  echo "           {b | build | out}" >&2
  echo "           {s | shell | zsh}" >&2
  echo "           {h | hash}" >&2
  echo "           {store | r | realise | gc | add | del}" >&2
  echo "           {r | repl}" >&2
  exit ${@:-1}
}

# Parse the command line.
origArgs=("$@")
extraNixFlags=()
exprArg=
action=
src=

while [ "$#" -gt 0 ]; do
  i="$1"; shift 1
  case "$i" in
    -h|--help)
      showUsage 0
      ;;
    --version|v|version)
      action='version'
      ;;
    i|instantiate)
      action='instantiate'
      ;;
    e|eval)
      action='instantiate'
      extraNixFlags+=('--eval')
      ;;
    drv)
      action='instantiate'
      extraNixFlags+=('-Q' '--indirect' '--add-root' "$PWD/result.drv")
      ;;
    b|build)
      action='build'
      extraNixFlags+=('--no-out-link')
      ;;
    out)
      action='build'
      extraNixFlags+=('-Q')
      ;;
    s|shell)
      action='shell'
      ;;
    zsh)
      action='shell'
      extraNixFlags+=('--run' 'zsh')
      ;;
    h|hash)
      action='hash'
      extraNixFlags+=('--type' 'sha256')
      ;;
    store)
      action='store'
      ;;
    r|realise)
      action='store'
      extraNixFlags+=('--realise')
      ;;
    gc)
      action='store'
      extraNixFlags+=('--gc' '--max-freed' '32G')
      ;;
    add)
      action='store'
      extraNixFlags+=('--add')
      ;;
    delete)
      action='store'
      extraNixFlags+=('--delete')
      ;;
    r|repl)
      action='repl'
      ;;
    --add-root)
      # nix-instantiate
      if [ -z "$1" ]; then
        echo "$0: \`$i' requires an argument"
        exit 1
      fi
      j="$1"; shift 1
      extraNixFlags+=("$i" "$j")
      ;;
    --option|--arg|--argstr)
      # nix-instantiate
      if [ -z "$1" -o -z "$2" ]; then
        echo "$0: \`$i' requires two arguments"
        exit 1
      fi
      j="$1"; shift 1
      k="$1"; shift 1
      extraNixFlags+=("$i" "$j" "$k")
      ;;
    --max-jobs|-j|--cores|--attr|-A|-I|--drv-link|--out-link|-o)
      # nix-build
      if [ -z "$1" ]; then
        echo "$0: \`$i' requires an argument"
        exit 1
      fi
      j="$1"; shift 1
      extraNixFlags+=("$i" "$j")
      ;;
    -r|--max-freed)
      # nix-store
      if [ -z "$1" ]; then
        echo "$0: \`$i' requires an argument"
        exit 1
      fi
      j="$1"; shift 1
      extraNixFlags+=("$i" "$j")
      ;;
    --)
      break
      ;;
    -*)
      extraNixFlags+=("$i")
      ;;
    *'.drv')
      src=$(readlink "$i")
      ;;
    './'*|'/'*|'<'*'>')
      src="$i"
      ;;
    *)
      echo "Unknown option: $i" >&2
      showUsage 129
      ;;
  esac
done

if [ -z "$action" ]; then action='repl'; fi

if [ -z "$src" -a -f ./default.nix ]; then
  src='./.'
fi

if [ "$#" -gt 0 ]; then
  extraNixFlags+=('-E')
  exprArg="$@"
fi

if [ -n "$src" -a -z "$exprArg" ]; then
  extraNixFlags+=("$src")
fi

if [ -n "$exprArg" ]; then
  if [ -f "$src" -o -f "$src/default.nix" ]; then
    if [ "$src" = ./. ]; then
      exprArg="with import ./. {}; $exprArg"
    else
      exprArg="with callPackage $src {}; $exprArg"
    fi
  fi

  if [ "$src" != ./. ]; then
    exprArg="with import <nixpkgs> {}; $exprArg"
  fi
fi

if [ "$action" = version ]; then
  version=$(nix-env --version | awk '{print $3}')
  echo "$0 (Nix) $version"
  exit 0
fi

if [ "$action" = instantiate ]; then
  if [ -z "$exprArg" ]; then
    exec nix-instantiate ${extraNixFlags[@]}
  else
    exec nix-instantiate ${extraNixFlags[@]} "$exprArg"
  fi
fi

if [ "$action" = build ]; then
  if [ -z "$exprArg" ]; then
    exec nix-build ${extraNixFlags[@]}
  else
    exec nix-build ${extraNixFlags[@]} "$exprArg"
  fi
fi

if [ "$action" = shell ]; then
  if [ -z "$exprArg" ]; then
    exec nix-shell ${extraNixFlags[@]}
  else
    exec nix-shell ${extraNixFlags[@]} "$exprArg"
  fi
fi

if [ "$action" = hash ]; then
  exec nix-hash ${extraNixFlags[@]}
fi

if [ "$action" = store ]; then
  exec nix-store ${extraNixFlags[@]}
fi

if [ "$action" = repl ]; then
  exec nix-repl '<nixpkgs/lib>' "${src:-<nixpkgs>}"
fi
