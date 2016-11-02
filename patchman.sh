#!/usr/bin/bash
#
# patchman: provide a utility for managing changes to packaged files
#
# Author:   Alastair Hughes
# Email:    hobbitalastair at yandex dot com
# Date:     24-9-2016

VERSION=0.1

PACBACK="./pacback"
PATCHDIR="./patches"
CACHEDIR="/var/cache/pacman/pkg/"

# Define some colors.
# Alternative start appears to be '\x1b['
C_ERR="\033[31;1m"
C_WARN="\033[33;1m"
C_OK="\033[32;1m"
C_BOLD="\033[39;1m"
C_RESET="\033[39;0m"

error() {
    local status="$1"
    shift
    message error "$@"
    exit "${status}"
}

message() {
    local level="$1"
    shift

    local fmt="%s\n"
    local min_level="0"

    case "${level}" in
        debug) fmt="DBG %s\n"
            min_level="2";;
        info) fmt="${C_OK}-->${C_RESET} %s\n"
            min_level="1";;
        warn) fmt="${C_WARN}>>>${C_RESET} %s\n";;
        error) fmt="${C_ERR}!!!${C_BOLD} %s${C_RESET}\n";;
        *) printf "${C_ERR}BUG${C_RESET} Unknown message format '%s'!\n" \
                "${level}" 1>&2
            exit 1;;
    esac

    # Add a timestamp if debug is set.
    if [ "${VERBOSE}" -ge 2 ]; then
        fmt="$(date '+%m:%S') ${fmt}"
    fi
    
    # Print the messages if the verboseness is high enough.
    if [ "${VERBOSE}" -ge "${min_level}" ]; then
        printf -- "${fmt}" "$@" 1>&2
    fi
}

list_changed() {
    # List the changed files.
    while IFS=" " read file sum pkg <&3; do
        if [ -e "${PATCHDIR}/${file}/IGNORE" ]; then
            message debug "Skipping ignored file ${file}"
        elif [ ! -r "/${file}" ]; then
            message warn "Skipping ${file}"
        else 
            newsum="$(md5sum "/${file}" | cut -d' ' -f1)"
            if [ -n "${newsum}" ] && [ "${newsum}" != "${sum}" ]; then
                message info "${file} has been changed"
            fi
        fi
    done 3< <("${PACBACK}")
}

get_pkg_owning() {
    # Print the name of the package owning the given file.
    pacman -Qqo "${file}"
    if [ "$?" -ne 0 ]; then
        error 1 "Could not find an owner for '${file}'"
    fi
}

get_pkg_file() {
    # Print the actual packaged file to stdout.
    local file="$1"

    if [ "${2}" != "extract" ]; then
        local bsdtar_args="-O"
    fi

    local pkgname
    pkgname="$(get_pkg_owning "${file}")" || return "$?"

    pkginfo="$(pacman -Qi --color=never "${pkgname}")" || \
        error 2 "Could not find information on package '${pkgname}'"
    version="$(printf "${pkginfo}" | grep '^Version' | \
        rev | cut -d' ' -f1 | rev)"
    arch="$(printf "${pkginfo}" | grep '^Architecture' | \
        rev | cut -d' ' -f1 | rev)"
    pkg="${CACHEDIR}/${pkgname}-${version}-${arch}"

    if [ ! -f "${pkg}".pkg.tar.* ]; then
        error 3 "Could not find package for ${pkgname}"
    else
        bsdtar "${bsdtar_args}" -xf "${pkg}".pkg.tar.* "${file:1}" || \
            error 3 "Failed to extract '${pkg}'!"
    fi
}

vimdiff_file() {
    # Generate a diff for the given file.
    local file="$1"
    vimdiff "${file}" <(get_pkg_file "${file}")
}

diff_file() {
    # Generate a diff for the given file.
    local file="$1"
    message debug "Generating diff for '${file}'"
    diff "${file}" <(get_pkg_file "${file}")
}

print_file() {
    # Print the unpatched file.
    local file="$1"
    message debug "Printing file for '${file}'"
    get_pkg_file "${file}"
}

revert() {
    # Revert the given file to the one provided by the package.
    local file="$1"
    message debug "Reverting '${file}'"
    pushd / > /dev/null
    get_pkg_file "${file}" "extract"
    popd > /dev/null
}


# Parse the arguments.
VERBOSE="${VERBOSE:-1}"
FILE_ARGS=false
ORIGINAL=false

LIST_CHANGED=false
VIMDIFF=false
DIFF=false
PRINT=false
REVERT=false
TARGETS=()
for arg in "$@"; do
    case "${arg}" in
        -h|--help)
            printf "${C_BOLD}%s${C_RESET} %s\n\n" "${0}" "${VERSION}"
            printf "Manage changes to packaged files.

    ${C_OK}-h|--help${C_RESET}               Print this message
    ${C_OK}-v|--version${C_RESET}            Print the version
    ${C_OK}-d|--debug${C_RESET}              Run verbosely
    ${C_OK}-q|--quiet${C_RESET}              Run quitely

    ${C_OK}-o|--original${C_RESET}           Use the original file unpatched

    ${C_OK}-l|--list-changed${C_RESET}       List the changed backup files
    ${C_OK}-i|--vimdiff <files>${C_RESET}    Interactively diff the files
    ${C_OK}-D|--diff <files>${C_RESET}       Diff the given files
    ${C_OK}-p|--print <files>${C_RESET}      Print the patched file
    ${C_OK}-r|--revert <files>${C_RESET}     Revert the given files

Author: Alastair Hughes <hobbitalastair at yandex dot com>\n"
            exit 0;;
        -v|--version)
            printf "%s version %s\n" "$0" "${VERSION}"
            exit 0;;
        -q|--quiet) export VERBOSE="0";;
        -d|--debug) export VERBOSE="2";;

        -o|--original) ORIGINAL="true";;

        -l|--list-changed) LIST_CHANGED="true";;
        -p|--print) PRINT="true"; FILE_ARGS="true";;
        -i|--vimdiff) VIMDIFF="true"; FILE_ARGS="true";;
        -D|--diff) DIFF="true"; FILE_ARGS="true";;
        -r|--revert) REVERT="true"; FILE_ARGS="true";;

        *) if "${FILE_ARGS}"; then
            TARGETS+=("${arg}")
        else 
            error 1 "Unknown argument '${arg}'"
        fi;;
    esac
done

# Check the results.
if [ "${#TARGETS[@]}" -eq 0 ] && "${FILE_ARGS}"; then
    message error "No targets given"
fi

if [ "$#" -eq 0 ]; then
    printf "${C_BOLD}%s${C_RESET} %s\n" "${0}" "${VERSION}" 1>&2
fi

if "${LIST_CHANGED}"; then
    list_changed
fi

for file in "${TARGETS[@]}"; do
    if [ ! -f "${file}" ]; then
        error 1 "Could not find file '${file}'"
    fi
    if "${PRINT}"; then
        print_file "${file}"
    fi
    if "${VIMDIFF}"; then
        vimdiff_file "${file}"
    fi
    if "${DIFF}"; then
        diff_file "${file}"
    fi
    if "${REVERT}"; then
        revert "${file}"
    fi
done
