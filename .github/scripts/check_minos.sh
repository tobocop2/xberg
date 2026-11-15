#!/bin/bash
# Fail when any Mach-O slice in the given wheels needs a macOS newer than the floor.
# Usage: check_minos.sh <floor, e.g. 11.0> <wheel>...
set -euo pipefail

floor="$1"
shift

newer() {
  # true when version $1 is greater than version $2
  [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n 1)" = "$1" ] && [ "$1" != "$2" ]
}

checked=0
for wheel in "$@"; do
  dir="$(mktemp -d)"
  unzip -q "$wheel" -d "$dir"
  while IFS= read -r -d '' file; do
    file -b "$file" | grep -q 'Mach-O' || continue
    for arch in $(lipo -archs "$file"); do
      slice="$(otool -arch "$arch" -l "$file")"
      minos="$(printf '%s\n' "$slice" | awk '
        /LC_BUILD_VERSION/ {build=1}
        /LC_VERSION_MIN_MACOSX/ {legacy=1}
        build && $1 == "minos" {print $2; exit}
        legacy && $1 == "version" {print $2; exit}')"
      if [ -z "$minos" ]; then
        echo "MINOS-FAIL $wheel $file $arch: no build version record" >&2
        exit 1
      fi
      echo "MINOS $(basename "$wheel") ${file#"$dir"/} $arch minos=$minos"
      if newer "$minos" "$floor"; then
        echo "MINOS-FAIL $wheel $file $arch: minos $minos is above $floor" >&2
        exit 1
      fi
      checked=$((checked + 1))
    done
  done < <(find "$dir" -type f \( -name '*.so' -o -name '*.dylib' \) -print0)
done

if [ "$checked" -eq 0 ]; then
  echo "MINOS-FAIL no Mach-O slice found in the wheels" >&2
  exit 1
fi
echo "MINOS-OK $checked slices at or below $floor"
