#! @shell@
set -e
set -o pipefail
export PATH=@path@:$PATH


showSyntax() {
    echo "$0: not implemented" >&2
    exit 1
}

showSyntax
