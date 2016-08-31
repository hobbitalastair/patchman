
CC = gcc
CFLAGS = -Wall -Werror -pedantic -std=c99 -g -Os -DDBPATH='"/var/lib/pacman"' -DROOTDIR='"/"' -DPKGEXT='".pkg.tar.xz"'
LDFLAGS = -lalpm
OBJS = $(patsubst %.c,%,$(wildcard *.c))

%: %.c
	# Indent and remove backups.
	indent -kr -nut $<
	rm $<~

	${CC} $< -o $@ ${CFLAGS} ${LDFLAGS}

all: $(OBJS)

clean:
	rm -f ${OBJS}

