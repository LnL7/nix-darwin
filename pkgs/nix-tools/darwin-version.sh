#! @shell@
set -e
set -o pipefail
export PATH=@path@:$PATH

showSyntax() {
  echo "darwin-version [--help|--darwin-revision|--nixpkgs-revision|--configuration-revision|--json]" >&2
}

case "$1" in
  --help)
    showSyntax
    ;;
  --darwin-revision)
    revision="$(jq --raw-output '.darwinRevision // "null"' < /run/current-system/darwin-version.json)"
    if [[ "$revision" == "null" ]]; then
      echo "$0: nix-darwin commit hash is unknown" >&2
      exit 1
    fi
    echo "$revision"
    ;;
  --nixpkgs-revision)
    revision="$(jq --raw-output '.nixpkgsRevision // "null"' < /run/current-system/darwin-version.json)"
    if [[ "$revision" == "null" ]]; then
      echo "$0: Nixpkgs commit hash is unknown" >&2
      exit 1
    fi
    echo "$revision"
    ;;
  --configuration-revision)
    revision="$(jq --raw-output '.configurationRevision // "null"' < /run/current-system/darwin-version.json)"
    if [[ "$revision" == "null" ]]; then
      echo "$0: configuration commit hash is unknown" >&2
      exit 1
    fi
    echo "$revision"
    ;;
  --json)
    cat /run/current-system/darwin-version.json
    ;;
  *)
    label="$(jq --raw-output '.darwinLabel // "null"' < /run/current-system/darwin-version.json)"
    if [[ "$label" == "null" ]]; then
      showSyntax
      exit 1
    fi
    echo "$label"
    ;;
esac

