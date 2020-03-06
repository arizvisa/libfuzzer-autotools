MAKEDIR = $(dir $(firstword $(MAKEFILE_LIST)))
VPATH = .

# Include utility macros and user configuration
include Makefile.inc
include Makefile.config

# Define some defaults that the user will likely use
$(eval $(call setcompiler,COMPILE,program,%.c))
$(eval $(call setcompiler,CXXCOMPILE,program,%.cc))
$(eval $(call setlinker,CXXLINK,program,$(LDADD)))
