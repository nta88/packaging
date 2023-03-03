#!/bin/bash
set -Eeuo pipefail
shopt -s inherit_errexit
umask 022

function main() {
  local name version bin_name files control_extra
  name="$1"
  version="$2"
  bin_name="$3"
  files="$4"
  control_extra="$(cat)"

  local file architecture
  while IFS= read -rd '' file; do
    case "$(basename "$file")" in
    *amd64*) architecture=amd64 ;;
    *x86_64*) architecture=amd64 ;;
    *arm64*) architecture=arm64 ;;
    *aarch_64*) architecture=arm64 ;;
    *) continue ;;
    esac

    local temp_dir
    temp_dir="$(mktemp -d)"

    mkdir -p -- "${temp_dir}/DEBIAN"
    cat <<EOF >"${temp_dir}/DEBIAN/control"
Package: ${name}
Version: ${version}
Architecture: ${architecture}
${control_extra}
EOF

    mkdir -p -- "${temp_dir}/usr/bin"
    cp -T -- "$file" "${temp_dir}/usr/bin/${bin_name}"
    chmod 755 -- "${temp_dir}/usr/bin/${bin_name}"

    dpkg-deb --root-owner-group -Zxz -b "$temp_dir" "${name}_${version}_${architecture}.deb"
  done < <(find . -mindepth 1 -type f -name "$files" -print0)
}

main "$@"
exit 0
