MAKEDIR := $(dir $(firstword $(MAKEFILE_LIST)))

# Include utility macros and user configuration
include Makefile.inc
include Makefile.config

# Define some defaults that the user will likely use
$(eval $(call setcompiler,COMPILE,%.c))
$(eval $(call setcompiler,CXXCOMPILE,%.cc))
$(eval $(call setlinker,CXXLINK,program,$(LDADD)))
