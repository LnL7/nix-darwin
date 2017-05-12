#! @shell@
set -e
set -o pipefail
export PATH=@path@:$PATH

evalNix() {
  nix-instantiate --eval --strict -E "with import <darwin> {}; $@"
}

evalAttrs() {
  evalNix "builtins.concatStringsSep \"\n\" (builtins.attrNames $@)"
}

evalOpt() {
  evalNix "options.$option.$@" 2>/dev/null
}

showSyntax() {
  echo "$0: <option>" >&2
  eval printf $(evalAttrs "options")
  echo
  exit 1
}

# Parse the command line.
origArgs=("$@")
option=

while [ "$#" -gt 0 ]; do
  i="$1"; shift 1
  case "$i" in
    --help)
      showSyntax
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
  evalOpt "default" || echo "no default"
  echo
  echo "Example:"
  evalOpt "example" || echo "no example"
  echo
  echo "Description:"
  eval printf $(evalOpt "description") || echo "no description"
  echo
else
  eval printf $(evalAttrs "options.$option")
  echo
fi
