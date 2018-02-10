SRCROOT=$(PWD)
MKDIR=$(SRCROOT)/mk
include $(MKDIR)/mk.conf

do_help: help

HOSTSYS=$(shell uname -s)

CP=? cp
MAKEOPT?=-j4
ifeq ($(HOSTSYS),Darwin)
	FTP=ftp
else
	FTP= curl -O
endif

TOOLDIR= $(SRCROOT)
TOOLBUILDDIR= $(TOOLDIR)/build
TOOLBUILDDIR?= $(TOOLDIR)/build


BUILD_TARGET= i686-elf-murgia

BINUTILS= binutils-2.26
GMP= gmp-6.1.0
MPC= mpc-1.0.3
MPFR= mpfr-3.1.4
GCC= gcc-6.1.0
NEWLIB= newlib-2.5.0.20170323

GMP_CONFIGURE_OPTS=					\
			--prefix $(TOOLBUILDDIR) \
			--with-gnu-ld;


MPFR_CONFIGURE_OPTS=					\
			--with-gnu-ld			\
			--prefix $(TOOLBUILDDIR) 	\
			--target=$(BUILD_TARGET)	\
			--with-gmp-build=$(TOOLBUILDDIR)/gmp;


MPC_CONFIGURE_OPTS=					\
			--with-gnu-ld			\
			--prefix $(TOOLBUILDDIR) 	\
			--target=$(BUILD_TARGET)	\
			--with-gmp=$(TOOLBUILDDIR)	\
			--with-mpfr=$(TOOLBUILDDIR);


BINUTILS_CONFIGURE_OPTS=				\
			--with-gnu-ld			\
			--prefix $(INSTALLDIR)		\
			--target=$(BUILD_TARGET)	\
			--without-isl			\
			--without-libs			\
			--without-headers		\
			--with-gmp=$(TOOLBUILDDIR) 	\
			--with-mpfr=$(TOOLBUILDDIR)	\
			--with-mpc=$(TOOLBUILDDIR);


GCC_CONFIGURE_OPTS=					\
			--prefix $(INSTALLDIR) 	\
			--with-gnu-ld			\
			--target=$(BUILD_TARGET)	\
			--enable-languages=c		\
			--disable-libssp		\
			--disable-libquadmath		\
			--without-libs			\
			--without-headers		\
			--with-newlib			\
			--with-build-sysroot=$(TOOLBUILDDIR)


EXTS += $(BINUTILS) $(GMP) $(MPFR) $(MPC) $(GCC) $(NEWLIB)

.PHONY: help gmp mpfr mpc binutils gcc install compile populate
ALL_PREDEP+= populate
ALL_TARGET+= gcc

help:
	@echo "This is the $(BUILD_TARGET) Toolchain Compiler."
	@echo 
	@echo "Run 'make all [INSTALLDIR=<install dir>]' to compile."
	@echo "Run 'make install to install in '/usr/local' (default) or INSTALLDIR."
	@echo "Run 'make populate' to download the required sources."
	@echo

$(EXTSDIR)/$(GMP).tar.bz2:
	(cd $(EXTSDIR); $(FTP) ftp.gnu.org:/pub/gnu/gmp/$(GMP).tar.bz2 )

$(EXTSDIR)/$(MPFR).tar.bz2:
	(cd $(EXTSDIR); $(FTP) ftp.gnu.org:/pub/gnu/mpfr/$(MPFR).tar.bz2 )

$(EXTSDIR)/$(MPC).tar.gz:
	(cd $(EXTSDIR); $(FTP) ftp.gnu.org:/pub/gnu/mpc/$(MPC).tar.gz )

$(EXTSDIR)/$(BINUTILS).tar.bz2:
	(cd $(EXTSDIR); $(FTP) ftp.gnu.org:/pub/gnu/binutils/$(BINUTILS).tar.bz2)

$(EXTSDIR)/$(GCC).tar.bz2:
	(cd $(EXTSDIR); $(FTP) ftp.gnu.org:/pub/gnu/gcc/$(GCC)/$(GCC).tar.bz2)

$(EXTSDIR)/$(NEWLIB).tar.gz:
	(cd $(EXTSDIR); $(FTP) sourceware.org:/pub/newlib/$(NEWLIB).tar.gz)

populate: $(EXTSDIR)/$(GMP).tar.bz2 \
          $(EXTSDIR)/$(MPFR).tar.bz2 \
          $(EXTSDIR)/$(MPC).tar.gz \
          $(EXTSDIR)/$(BINUTILS).tar.bz2 \
          $(EXTSDIR)/$(GCC).tar.bz2 \
          $(EXTSDIR)/$(NEWLIB).tar.gz

.gmp.built:
	mkdir -p $(TOOLBUILDDIR)/gmp;
	(cd $(TOOLBUILDDIR)/gmp; $(EXTSDIR)/$(GMP)/configure $(GMP_CONFIGURE_OPTS))
	$(MAKE) $(MAKEOPT) -C $(TOOLBUILDDIR)/gmp install
	touch .gmp.built

gmp: .gmp.built

.mpfr.built: 
	mkdir -p $(TOOLBUILDDIR)/mpfr;
	(cd $(TOOLBUILDDIR)/mpfr; $(EXTSDIR)/$(MPFR)/configure $(MPFR_CONFIGURE_OPTS))
	$(MAKE) $(MAKEOPT) -C $(TOOLBUILDDIR)/mpfr install
	touch .mpfr.built

mpfr: gmp
	$(MAKE) .mpfr.built

.mpc.built:
	mkdir -p $(TOOLBUILDDIR)/mpc;
	(cd $(TOOLBUILDDIR)/mpc; $(EXTSDIR)/$(MPC)/configure $(MPC_CONFIGURE_OPTS))
	$(MAKE) $(MAKEOPT) -C $(TOOLBUILDDIR)/mpc install
	touch .mpc.built

mpc: mpfr
	$(MAKE) .mpc.built

# Ensure we can find the just compiled libraries during gcc bootstrap
export LDFLAGS=-Wl,-rpath,$(TOOLBUILDDIR)/lib
export CFLAGS=-Wno-error

.binutils.built:
	mkdir -p $(TOOLBUILDDIR)/binutils;
	(cd $(TOOLBUILDDIR)/binutils; $(EXTSDIR)/$(BINUTILS)/configure $(BINUTILS_CONFIGURE_OPTS))
	$(MAKE) $(MAKEOPT) -C $(TOOLBUILDDIR)/binutils
	touch .binutils.built

binutils: gmp mpfr mpc
	$(MAKE) .binutils.built

.gcc.built:
	-ln -s $(EXTSDIR)/$(MPFR) $(EXTSDIR)/$(GCC)/mpfr
	-ln -s $(EXTSDIR)/$(MPC) $(EXTSDIR)/$(GCC)/mpc
	-ln -s $(EXTSDIR)/$(GMP) $(EXTSDIR)/$(GCC)/gmp
	-for i in $(EXTSDIR)/$(BINUTILS)/*/; do \
		(cd $(EXTSDIR)/$(GCC); ln -s $$i); \
	done
	-ln -s $(EXTSDIR)/$(NEWLIB)/newlib $(EXTSDIR)/$(GCC)/newlib
	mkdir -p $(TOOLBUILDDIR)/gcc;
	(cd $(TOOLBUILDDIR)/gcc; $(EXTSDIR)/$(GCC)/configure $(GCC_CONFIGURE_OPTS))
	$(MAKE) $(MAKEOPT) -C $(TOOLBUILDDIR)/gcc
	touch .gcc.built

gcc:
	$(MAKE) .gcc.built

toolchain_install:
	$(MAKE) $(MAKEOPT) -C $(TOOLBUILDDIR)/gcc install

.PHONY: clean_markers clean_build
clean_markers:
	-rm .mpc.built .mpfr.built .gmp.built .binutils.built .gcc.built
clean_build:
	-rm -rf build

CLEAN_TARGET+= clean_markers clean_build

INSTALL_TARGET+=toolchain_install

include $(MKDIR)/exts.mk
include $(MKDIR)/def.mk
