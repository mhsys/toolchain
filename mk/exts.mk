.phony: externals clean_externals

externals:
	for i in $(EXTS); do \
		if [ ! -d $(EXTSRCDIR)/$$i ]; then \
			(cd $(EXTSRCDIR); \
			if [ -f $$i.tar.gz ]; then \
				$(TAR) xzf $$i.tar.gz; \
			elif [ -f $$i.tar.bz2 ]; then \
				$(TAR) xjf $$i.tar.bz2; \
			else \
				$(TAR) xJf $$i.tar.xz; \
			fi; \
			if [ -f $$i.patch ]; \
				then $(PATCH) -p0 < $$i.patch; \
			fi; ); \
		fi \
	done

clean_externals:
	for i in $(EXTS); do rm -rf $(EXTSRCDIR)/$$i; done

ALL_PREDEP+= externals
CLEAN_TARGET+= clean_externals
