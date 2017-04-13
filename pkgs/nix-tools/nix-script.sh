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
  echo "           {store | q | query | r | realise | gc | add | delete}" >&2
  echo "           {repl}" >&2
  echo "           {-q | -i | -e | -u}" >&2
  exit ${@:-1}
}

# Parse the command line.
origArgs=("$@")
extraNixFlags=()
srcArgs=()
pkgArgs=()
exprArg=
action=

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
      extraNixFlags+=('-Q')
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
    q|query)
      action='store'
      extraNixFlags+=('--query')
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
    repl)
      action='repl'
      ;;
    -q)
      action='env'
      extraNixFlags+=("$i")
      ;;
    -iA|-i|-e|-u)
      action='env'
      extraNixFlags+=("$i")
      if [ -z "$1" ]; then
        echo "$0: \`$i' requires an argument"
        exit 1
      fi
      j="$1"; shift 1
      extraNixFlags+=("$i" "$j")
      ;;
    -j[0-9]*)
      extraNixFlags+=("$i")
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
    --command|--run|-i)
      # nix-shell
      if [ -z "$1" ]; then
        echo "$0: \`$i' requires an argument"
        exit 1
      fi
      j="$1"; shift 1
      extraNixFlags+=("$i" "$j")
      ;;
    --packages|-p)
      # nix-shell
      if [ -z "$1" ]; then
        echo "$0: \`$i' requires an argument"
        exit 1
      fi
      pkgArgs+=("$i")
      while [ "$#" -gt 0 ]; do
        case "$1" in
          -*|*.nix|'<'*'>'|'./'*|'/'*|'http://'*|'https://'*)
            break
            ;;
          *)
            j="$1"; shift 1
            pkgArgs+=("$j")
            ;;
        esac
      done
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
    './.'|'<'*'>'|'http://'*|'https://'*)
      pkgArgs+=("$i")
      ;;
    *'.drv')
      drvArgs+=("$(readlink "$i")")
      ;;
    *'.nix'|'./'*|'/'*)
      srcArgs+=("$i")
      ;;
    *)
      echo "Unknown option: $i" >&2
      showUsage 129
      ;;
  esac
done

if [ -z "$action" ]; then action='repl'; fi

if [ -z "$pkgArgs" ]; then
  if [ -f ./default.nix ]; then pkgArgs+=('./.'); fi
  pkgArgs+=('<nixpkgs>')
fi

exprArg="$@"
for f in ${srcArgs[@]}; do
  exprArg="${exprArg:+with }callPackage $f {}${exprArg:+; $exprArg}"
done
for p in ${pkgArgs[@]}; do
  exprArg="${exprArg:+with }import $p {}${exprArg:+; $exprArg}"
done

if [ "$action" = version ]; then
  version=$(nix-env --version | awk '{print $3}')
  echo "$0 (Nix) $version"
  exit 0
fi

if [ "${traceExpr:-0}" -eq 1 ]; then
  if [ "$#" -eq 0 -a -z "$srcArgs" ]; then
    echo "nix-$action ${pkgArgs[@]} ${srcArgs[@]} ${drvArgs[@]} ${extraNixFlags[@]}" >&2
  else
    echo "nix-$action ${extraNixFlags[@]} -E '$exprArg'" >&2
  fi
fi

if [ "$action" = instantiate ]; then
  if [ "$#" -eq 0 -a -z "$srcArgs" ]; then
    exec nix-instantiate ${pkgArgs[@]} ${extraNixFlags[@]}
  fi
  exec nix-instantiate ${extraNixFlags[@]} -E "$exprArg"
fi

if [ "$action" = build ]; then
  if [ "$#" -eq 0 -a -z "$srcArgs" ]; then
    exec nix-build ${pkgArgs[@]} ${extraNixFlags[@]}
  fi
  exec nix-build ${extraNixFlags[@]} -E "$exprArg"
fi

if [ "$action" = shell ]; then
  if [ -n "$drvArgs" ]; then
    exec nix-shell ${drvArgs[@]} ${extraNixFlags[@]}
  fi
  if [ "$#" -eq 0 -a -z "$srcArgs" ]; then
    exec nix-shell ${pkgArgs[@]} ${extraNixFlags[@]}
  fi
  exec nix-shell ${extraNixFlags[@]} -E "$exprArg"
fi

if [ "$action" = hash ]; then
  exec nix-hash ${srcArgs[@]} ${extraNixFlags[@]}
fi

if [ "$action" = store ]; then
  if [ -n "$drvArgs" ]; then
    exec nix-shell ${drvArgs[@]} ${extraNixFlags[@]}
  fi
  exec nix-store ${srcArgs[@]} ${extraNixFlags[@]}
fi

if [ "$action" = env ]; then
  exec nix-env -f '<nixpkgs>' ${extraNixFlags[@]}
fi

if [ "$action" = repl ]; then
  exec nix-repl '<nixpkgs/lib>' ${pkgArgs[@]} ${srcArgs[@]}
fi
