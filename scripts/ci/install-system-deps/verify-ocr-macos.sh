#!/usr/bin/env bash
set -euo pipefail

verify_ocr_macos() {
  local tess_prefix lept_prefix output
  tess_prefix="$(brew --prefix tesseract)"
  lept_prefix="$(brew --prefix leptonica)"
  export PKG_CONFIG_PATH="$tess_prefix/lib/pkgconfig:$lept_prefix/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
  # Homebrew ships only its newest Tesseract bottle, so the floor is 5.5.4 (the security
  # patch) or a later 5.5 patch. The Python wheel does not link this copy: the default
  # static-linking feature builds and statically links the pinned 5.5.4 source. Only the
  # tesseract-dynamic feature, which the wheel never turns on, uses pkg-config. ~keep
  local tess_version
  tess_version="$(pkg-config --modversion tesseract)"
  [[ "$tess_version" =~ ^5\.5\.([4-9]|[1-9][0-9]+)$ ]] || {
    echo 'Expected Tesseract pkg-config 5.5.4 or a later 5.5 patch' >&2
    return 1
  }
  [ "$(pkg-config --modversion lept)" = 1.87.0 ] || {
    echo 'Expected Leptonica pkg-config 1.87.0' >&2
    return 1
  }
  output="$(tesseract --version 2>&1)"
  grep -qxF "tesseract $tess_version" <<<"$output" || {
    echo "Expected actual Tesseract CLI 5.5.4 or a later 5.5 patch, matching pkg-config $tess_version" >&2
    return 1
  }
  grep -q 'leptonica-1\.87\.0\([^0-9.]\|$\)' <<<"$output" || {
    echo 'Expected actual Leptonica runtime 1.87.0' >&2
    return 1
  }
  printf '%s\n' "$output"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  verify_ocr_macos
fi
