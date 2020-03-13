MAKEDIR = $(dir $(firstword $(MAKEFILE_LIST)))
VPATH = .

SANITIZER_TYPE = address
#SANITIZER_TYPE = safe-stack

FUZZ_CFLAGS = -g -fno-omit-frame-pointer -O0 -fsanitize=fuzzer,$(SANITIZER_TYPE)
FUZZ_LDFLAGS = -g -fno-omit-frame-pointer -O0 -fsanitize=fuzzer,$(SANITIZER_TYPE)

# Include utility macros and user configuration
include Makefile.inc
include Makefile.config

# Define some defaults that the user will likely use
$(eval $(call setcompiler,COMPILE,program,%.c))
$(eval $(call setcompiler,CXXCOMPILE,program,%.cc))
$(eval $(call setlinker,CXXLINK,program,$(LDADD)))
