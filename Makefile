include Makefile.inc
include Makefile.config

$(eval $(call setcompiler,COMPILE,%.c))
$(eval $(call setcompiler,CXXCOMPILE,%.cc))
$(eval $(call setlinker,CXXLINK,program,$(LDADD)))
