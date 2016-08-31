#!/usr/bin/bash

PAGER="less -FR"
DIFF="diff --color=always"
CACHEDIR="/var/cache/pacman/pkg/"

get_pkg_file() {
    local file="$1"
    local pkg="$2"

    if [ ! -f "${CACHEDIR}/${pkg}" ]; then
        printf "error: could not find ${pkg}!\n" 1>&2
    else
        bsdtar -O -xf "${CACHEDIR}/${pkg}" "${file}"
    fi
}

handle_diff() {
    # Handle the differing files interactively.
    local file="$1"
    local pkg="$2"

    local running=true
    local input
    while ${running}; do
        printf '>>> '
        read input
        case "${input}" in
            r|revert)
                printf "Are you sure? [y/N] "
                read input
                if [ "${input}" == 'y' ] || [ "${input}" == 'Y' ]; then
                    get_pkg_file "${file}" "${pkg}" > "/${file}"
                fi;;
            g|generate) printf "Not implemented!\n" 1>&2;;
            h|help) cat 1>&2 << EOF
Usage:
r - revert the file
d - print a diff of the files
f - save the file elsewhere
g - generate a patch for the file
c - continue
q - quit
h - print this message
EOF
;;
            d|diff) get_pkg_file "${file}" "${pkg}" | $DIFF - "/${file}" | \
                $PAGER;;
            f|file) printf "Copy to: "
                read input
                if [ -n "${input}" ]; then
                    cp -v "/${file}" "${input}"
                fi;;
            c|cancel) running=false;;
            q|quit) exit 0;;
            *) printf "error: unknown input '%s' - use 'h' for help\n" \
                "${input}" 1>&2;;
        esac
    done
}

while IFS=" " read file sum pkg <&3; do
    newsum="$(md5sum "/${file}" | cut -d' ' -f1)"
    if [ -n "${newsum}" ] && [ "${newsum}" != "${sum}" ]; then
        printf "%s:\n" "${file}"
        handle_diff "${file}" "${pkg}"
    fi
done 3< <(./pacback)
