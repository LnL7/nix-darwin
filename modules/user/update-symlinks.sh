scratch=$(mktemp -d -t tmp.XXXXXXXXXX)
update_symlink() {
    local SRC
    local DEST
    local OUTDIR

    SRC="$1"
    DEST="$2"
    OUTDIR=$(dirname "$DEST");
    if [ ! -d "$OUTDIR" ]; then
        if [ ! -z "${SUDO:-}" ]; then
            sudo mkdir -p "$OUTDIR"
        else
            mkdir -p "$OUTDIR"
        fi
    fi

    if [ ! -h "$DEST" ] && [ -d "$DEST" ]; then
        echo "DEST ($DEST) is a directory??"
        return 1
    fi

    if [ -f "$DEST" ]; then
        local CURSRC
        CURSRC=$(realpath "$DEST")
        if [ "x$CURSRC" == "x$SRC" ]; then
            return 0
        fi
    fi

    if [ -d "$DEST" ]; then
        rm "$DEST"
    fi

    ln -s "$SRC" "$scratch/tmp"
    if [ ! -z "${SUDO:-}" ]; then
        sudo mv "$scratch/tmp" "$DEST"
    else
        mv "$scratch/tmp" "$DEST"
    fi
}
