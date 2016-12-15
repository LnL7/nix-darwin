#! @shell@
set -e
set -o pipefail
export PATH=@path@:$PATH


showSyntax() {
  echo "$0: not implemented" >&2
  exit 1
}

evalNix() {
  nix-instantiate --eval --strict -E "with import <darwin> {}; $@"
}

evalAttrs() {
  evalNix "builtins.concatStringsSep \"\n\" (builtins.attrNames $@)"
}

evalOpt() {
  evalNix "options.$option.$@" || true
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

if [ "$(evalOpt "_type" 2> /dev/null)" = '"option"' ]; then
  echo "Value:"
  evalOpt "value"
  echo
  echo "Default:"
  evalOpt "default"
  echo
  echo "Example:"
  evalOpt "example"
  echo
  echo "Description:"
  eval printf $(evalOpt "description")
  echo
else
  eval printf $(evalAttrs "options.$option")
  echo
fi
