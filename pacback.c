/* pacback.c
 *
 * Print a list of the pacman backup files, along with the corresponding
 * package name and md5sum.
 *
 * Author:  Alastair Hughes
 * Contact: <hobbitalastair at yandex dot com>
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <alpm.h>
#include <alpm_list.h>

/* Generate the name of the given package file.
 * This needs to be freed afterwards!
 */
char *get_pkg_name(alpm_pkg_t * pkg)
{
    const char *pkgname = alpm_pkg_get_name(pkg);
    const char *version = alpm_pkg_get_version(pkg);
    const char *arch = alpm_pkg_get_arch(pkg);
    const char *ext = PKGEXT;

    /* Allocate enough memory for the name and delimiters */
    char *name = malloc(strlen(pkgname) + 1 + strlen(version) + 1 +
                        strlen(arch) + strlen(ext) + 1);
    size_t offset = 0;

    while (*pkgname) {
        name[offset] = *pkgname;
        offset++;
        pkgname++;
    }
    name[offset] = '-';
    offset++;
    while (*version) {
        name[offset] = *version;
        offset++;
        version++;
    }
    name[offset] = '-';
    offset++;
    while (*arch) {
        name[offset] = *arch;
        offset++;
        arch++;
    }
    while (*ext) {
        name[offset] = *ext;
        offset++;
        ext++;
    }
    name[offset] = '\0';

    return name;
}

int main()
{
    alpm_errno_t err = 0;
    alpm_handle_t *alpm_handle = alpm_initialize(ROOTDIR, DBPATH, &err);
    if (err != 0) {
        fprintf(stderr, "Failed to initialise alpm: %s\n",
                alpm_strerror(err));
        return EXIT_FAILURE;
    }

    alpm_db_t *db = alpm_get_localdb(alpm_handle);
    alpm_list_t *pkgs;
    alpm_list_t *backups;
    alpm_pkg_t *pkg;
    alpm_backup_t *backup;
    char *pkgname;
    for (pkgs = alpm_db_get_pkgcache(db); pkgs;
         pkgs = alpm_list_next(pkgs)) {
        pkg = pkgs->data;
        backups = alpm_pkg_get_backup(pkg);
        if (backups) {
            pkgname = get_pkg_name(pkg);
            for (; backups; backups = alpm_list_next(backups)) {
                backup = backups->data;
                printf("%s %s %s\n", backup->name, backup->hash, pkgname);
            }
            free(pkgname);
        }
    }

    return EXIT_SUCCESS;
}
