#!/usr/bin/bash

PAGER="less"

gen_diff() {
    # Diff the given filename with the one in the package.
    local file="$1"
    local pkg="$2"

    if [ ! -f "${CACHEDIR}/${pkg}" ]; then
        printf "error: could not find ${pkg}!\n" 1>&2
    else
        bsdtar -O -xf "${CACHEDIR}/${pkg}" "${file}" | \
            diff - "/${file}" | $PAGER
    fi
}

revert() {
    # Revert the file to the one in the package.
    local file="$1"
    local pkg="$2"

    if [ ! -f "${CACHEDIR}/${pkg}" ]; then
        printf "error: could not find ${pkg}!\n" 1>&2
    else
        bsdtar -O -xf "${CACHEDIR}/${pkg}" "${file}" > "/${file}"
    fi
}

handle_diff() {
    # Handle the differing files interactively.
    local file="$1"
    local pkg="$2"

    local running=true
    local input
    while ${running}; do
        read input
        case "${input}" in
            r|revert) revert "${file}" "${pkg}";;
            g|generate) printf "Not implemented!\n" 1>&2;;
            h|help) cat 1>&2 << EOF
Usage:
r - revert the file
d - print a diff of the files
g - generate a patch for the file
c - continue
q - quit
h - print this message
EOF
;;
            d|diff) gen_diff "${file}" "${pkg}";;
            c|cancel) running=false;;
            q|quit) exit 0;;
            *) printf "error: unknown input '%s' - use 'h' for help\n" \
                "${input}" 1>&2;;
        esac
    done
}

CACHEDIR="/var/cache/pacman/pkg/"
while IFS=" " read file sum pkg <&3; do
    newsum="$(md5sum "/${file}" | cut -d' ' -f1)"
    if [ -n "${newsum}" ] && [ "${newsum}" != "${sum}" ]; then
        printf "%s, %s, %s\n" "${file}" "${sum}" "${newsum}"
        handle_diff "${file}" "${pkg}"
    fi
done 3< <(./pacback)
