# Makefile for patchman

BINDIR = /usr/bin
LIBEXECDIR = /usr/lib/patchman
# patch database for patchman
PATCHDIR = /var/lib/patchman
# pacman's pkg cache
PACCACHEDIR = /var/cache/pacman/pkg
# pacman's database path
DBPATH = /var/lib/pacman

CC = gcc
CFLAGS = -Wall -Werror -pedantic -std=c99 -g -Os \
	 -DDBPATH='"$(DBPATH)"' -DROOTDIR='"/"' -DPKGEXT='".pkg.tar.xz"'
LDFLAGS = -lalpm
OBJS = $(patsubst %.c,%,$(wildcard *.c)) patchman.sh

%: %.c
	${CC} $< -o $@ ${CFLAGS} ${LDFLAGS}

%.sh: %.in
	sed $< \
	    -e 's:@PACBACK@:$(LIBEXECDIR)/pacback:' \
	    -e 's:@PATCHDIR@:$(PATCHDIR):' \
	    -e 's:@PACCACHEDIR@:$(PACCACHEDIR):' > $@

all: $(OBJS)

clean:
	rm -f ${OBJS}

install: all
	install -Dm0755 patchman.sh "$(DESTDIR)$(BINDIR)/patchman.sh"
	install -Dm0755 pacback "$(DESTDIR)$(LIBEXECDIR)/pacback"

