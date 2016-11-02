# pacback #

File manager script

## Goals ##

- patchman replacement - manage patches to files
- Provide a utility for monitoring backup files
- Provide a utility for creating patches between modified and packaged files
- Provide a utility for cleaning up uneeded changes
- Use hooks for automation of updating files

## Hooks ##

Hooks need to run if:
- A .pacnew file is generated (attempt to merge automatically, potentially
  problematic with the current architecture)
- A file in the "drop-in" db is changed.

## Drop-in DB ##

Store patches in `/var/lib/patchman/<path>`.

Order of handling for patches:
- IGNORE                Don't list this file normally
- `<path>` is a file    Use the file instead
- `*.patch`             Apply the patches

