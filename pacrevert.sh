#!/usr/bin/sh
# Revert files to the package provided one.
# Author:   Alastair Hughes
# Date:     4-9-2016

ROOT="${ROOT-/}"
CACHEDIR="${CACHEDIR-$ROOT/var/cache/pacman/pkg/}"

replace_file() {
    # Replace the given file.
    local file="$1"
    local pkgname pkginfo version arch pkg

    # Find the owning package.
    pkgname="$(pacman -Qqo "${file}")" || \
        return 1
    pkginfo="$(pacman -Qi --color=never "${pkgname}")"
    version="$(printf "${pkginfo}" | grep '^Version' | \
        rev | cut -d' ' -f1 | rev)"
    arch="$(printf "${pkginfo}" | grep '^Architecture' | \
        rev | cut -d' ' -f1 | rev)"
    pkg="${pkgname}-${version}-${arch}"

    # Extract the file.
    cd "${ROOT}"
    bsdtar -xf "${CACHEDIR}/${pkg}.pkg.tar".* "${file:1}" || \
        return 1
}

# Parse the arguments.
TARGETS=""
HELP=false
for arg in "$@"; do
    case "${arg}" in
        -h|--help) HELP="true";;
        *) TARGETS+=" ${arg}";;
    esac
done

if "${HELP}"; then
    cat << EOF
Revert the given files to the one provided in the package.
$0
    -h,--help   Print this usage message
    <files>     Revert these files
EOF
    exit 0
fi

if [ "$#" -eq 0 ]; then
    echo "$0 [-h|--help] <files>" 1>&2
    exit 1
fi

for target in ${TARGETS}; do
    replace_file "${target}"
done
