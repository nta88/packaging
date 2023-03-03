#!/bin/bash
set -Eeuo pipefail
shopt -s inherit_errexit

function main() {
  local name repo
  name="$1"
  repo="$2"

  echo "Fetch ${name} latest release metadata ..." >&2
  local release_meta
  release_meta="$(curl -fsSL \
    --header "Authorization: Bearer ${GITHUB_TOKEN:--}" \
    "https://api.github.com/repos/${repo}/releases/latest")"

  # Save release file
  local release_file
  release_file="$(readlink -m -- "${name}.release")"
  jq -Mr <<<"$release_meta" >"$release_file"
  printf 'GHR_RELEASE_FILE=%s\n' "$release_file"

  # Set version and tag name
  local version
  version="$(jq -Mr '.tag_name' <<<"$release_meta")"
  version="$(LANG=C sed 's/[^a-zA-Z0-9_.-]/_/g' <<<"$version")"
  if [[ "$version" =~ ^v[0-9] ]]; then version="${version:1}"; fi
  printf 'GHR_VERSION=%s\n' "$version"

  local tag_name
  tag_name="${name}_${version}"
  printf 'GHR_TAG_NAME=%s\n' "$tag_name"
  printf "Tag name: %s\n" "$tag_name" >&2

  # Check if release already exists
  local release_code
  release_code="$(curl -sL -o /dev/null -w '%{http_code}' "${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/releases/tags/${tag_name}")"
  if [[ "$release_code" -eq 200 ]]; then
    printf 'GHR_EXISTS=1\n'
    printf "Release already exists\n" >&2
  else
    printf 'GHR_EXISTS=0\n'
  fi
}

main "$@"
exit 0
