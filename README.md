# The Murgia Hack toolchain

This repository contains all you need to compile the Murgia Hack
toolchain, needed to compile the Murgia Hack system.

## Compilation

First you need to decide where to install the tools. By default will
be installed in `/usr/local`.

If you want to install the tools in /usr/local, type:

    $ make all
    $ sudo -s -- make install

Otherwise specify the installation directory `dir` with:

    $ make all INSTALLDIR=`<dir>`
    $ make install

This will install the `i686-elf-murgia-*` binaries, as well as the
newlib libc for the MH system.

## Downloading sources

Note that during 'make all' sources for binutils, gcc and newlib will be downloaded. If you want to only download the sources, type:

    $ make populate
