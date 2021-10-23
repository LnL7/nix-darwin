#! @shell@
set -e
set -o pipefail
export PATH=@path@:$PATH

evalNix() {
  nix-instantiate --eval --strict "${extraEvalFlags[@]}" -E "with import <darwin> {}; $*"
}

evalAttrs() {
  evalNix "builtins.concatStringsSep \"\\n\" (builtins.attrNames $*)"
}

evalOpt() {
  evalNix "options.$option.$*" 2>/dev/null
}

evalOptText() {
  eval printf "$(evalNix "options.$option.$*" 2>/dev/null)" 2>/dev/null
  echo
}

showSyntax() {
  echo "$0: [-I path] <option>" >&2
  eval printf "$(evalAttrs "options")"
  echo
  exit 1
}

# Parse the command line.
origArgs=("$@")
extraEvalFlags=()
option=

while [ "$#" -gt 0 ]; do
  i="$1"; shift 1
  case "$i" in
    --help)
      showSyntax
      ;;
    -I)
      if [ -z "$1" ]; then
        echo "$0: ‘$i’ requires an argument"
        exit 1
      fi
      j="$1"; shift 1
      extraEvalFlags+=("$i" "$j")
      ;;
    *)
      option="$i"
      ;;
  esac
done

if [ -z "$option" ]; then showSyntax; fi

if [ "$(evalOpt "_type")" = '"option"' ]; then
  echo "Value:"
  evalOpt "value" || echo "no value"
  echo
  echo "Default:"
  evalOpt "default" || evalOptText "defaultText" || echo "no default"
  echo
  echo "Example:"
  if [ "$(evalOpt "example._type")" = '"literalExpression"' ]; then
    evalOptText "example.text" || echo "no example"
  else
    evalOpt "example" || echo "no example"
  fi
  echo
  echo "Description:"
  evalOptText "description" || echo "no description"
  echo
else
  eval printf "$(evalAttrs "options.$option")" 2>/dev/null
  echo
fi
