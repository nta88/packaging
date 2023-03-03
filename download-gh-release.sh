#!/bin/bash
set -Eeuo pipefail
shopt -s inherit_errexit

function main() {
  local pattern download_urls download_url download_name
  pattern="$1"
  download_urls="$(jq -Mr --arg pattern "$pattern" \
    '.assets[] | select(.name|test("^(\($pattern))$")) | .browser_download_url')"

  while IFS= read -rd $'\n' download_url; do
    download_name="${download_url##*/}"
    download_name="${download_name%%\?*}"
    download_name="${download_name%%\#*}"
    curl -fL -o "$download_name" -- "$download_url"
  done <<<"$download_urls"
}

main "$@"
exit 0
