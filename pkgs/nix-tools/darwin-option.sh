#! @shell@
set -e
set -o pipefail

export PATH=@path@
export NIX_PATH=${NIX_PATH:-@nixPath@}

evalNix() {
  nix-instantiate --eval --strict "${extraEvalFlags[@]}" -E "with import <darwin> {}; $*" 2>/dev/null
}

evalOpt() {
  evalNix "options.$option.$*"
}

evalOptAttrs() {
  evalNix "builtins.concatStringsSep \"\\n\" (builtins.attrNames $*)" | jq -r .
}

evalOptText() {
  evalNix "options.$option.$*" | jq -r .
}

showSyntax() {
  echo "$0: [-I path] <option>" >&2
  evalOptAttrs "options"
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
  evalOptText "description.text" || echo "no description"
  echo
else
  evalOptAttrs "options.$option"
fi
