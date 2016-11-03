# pacback #

pacman-specific script for managing changes to system files.

## Drop-in DB ##

Store patches in `/var/lib/patchman/<path>`.

Order of handling for patches:
- IGNORE                Don't list this file normally
- `<path>` is a file    Use the file instead
- `*.patch`             Apply the patches

## Notes ##

I originally wanted to use hooks to automate updating files.
However, doing so requires a "before and after" view of the files, to avoid
overwriting custom changes.
This largely defeats the purpose of having a "drop-in" folder - patchman.sh
would need to provide an argument for adding, removing, and updating files,
which would need to be (awkwardly) run by the install script of the packages.
It also completely fails to work with hooks, since we can't automatically
apply patches on updates to files.

Instead, I'll resort to manually applying and removing patches.

## TODO ##

Things I'd like to add:
- Tests
- Documentation (man page)

