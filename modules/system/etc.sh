# Set up the statically computed bits of /etc.
echo "setting up /etc..." >&2

declare -A etcSha256Hashes
@etcSha256Hashes@

# shellcheck disable=SC2154
ln -sfn "$(readlink -f "$systemConfig/etc")" /etc/static

while IFS= read -r -d '' f; do # for f in find /etc/static/* -type l
  l=/etc/''${f#/etc/static/}
  d=''${l%/*}
  if [ ! -e "$d" ]; then
    mkdir -p "$d"
  fi
  if [ -e "$l" ]; then
    if [ "$(readlink "$l")" != "$f" ]; then
      if ! grep -q /etc/static "$l"; then
        o=''$(shasum -a256 "$l")
        o=''${o%% *}
        for h in ${etcSha256Hashes["$l"]}; do
          if [ "$o" = "$h" ]; then
            mv "$l" "$l.orig"
            ln -s "$f" "$l"
            break
          else
            h=
          fi
        done

        if [ -z "$h" ]; then
          echo "[1;31merror: not linking environment.etc.\"${l#/etc/}\" because $l already exists, skipping...[0m" >&2
          echo "[1;31mexisting file has unknown content $o, move and activate again to apply[0m" >&2
        fi
      fi
    fi
  else
    ln -s "$f" "$l"
  fi
done < <(find /etc/static/* -type l -print0)

while IFS= read -r -d '' l; do # for l in find /etc/* -type l
  # shellcheck disable=SC2001
  f="$(echo "$l" | sed 's,/etc/,/etc/static/,')"
  f=/etc/static/''${l#/etc/}
  if [ "$(readlink "$l")" = "$f" ] && [ ! -e "$(readlink -f "$l")" ]; then
    rm "$l"
  fi
done < <(find /etc/* -type l 2> /dev/null)
