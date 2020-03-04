## Assign the cflags and ldflags for libfuzzer
FUZZ_CFLAGS = -g -fno-omit-frame-pointer -O2 -fsanitize=fuzzer,address
FUZZ_LDFLAGS = -g -fno-omit-frame-pointer -O2 -fsanitize=fuzzer,address

## Define some utility macros for helping out with dependencies

# setcompiler(compile-var, pattern)
define setcompiler
%.$$(OBJEXT): $(2)
	$$($(1)) $$(FUZZ_CFLAGS) -o $$@ -c $$<
endef

# setlinker(link-var, name, ladds)
define setlinker

%.fuzzer: %.o
	$$($(1)) $$(FUZZ_LDFLAGS) \
	$$(foreach item,$$($(2)_LDADD),$$(if $$(filter-out -%,$$(item)),$($(2)_VPATH)/$$(item),$$(item))) \
	$$(foreach object,$$($(2)_OBJECTS),$($(2)_VPATH)/$$(object)) \
	$$(foreach object,$$($(2)_DEPENDENCIES),$($(2)_VPATH)/$$(object)) \
	$(3) $$^ -o $$@
endef

# link(link-var, target, ldeps, ladds, rbase, robjs-var, radds-var, rdeps-var)
define link
$(2): $(3)
	$$($(1)) $$(FUZZ_LDFLAGS) \
	$$(foreach item,$$($(7)),$$(if $$(filter-out -%,$$(item)),$(5)/$$(item),$$(item))) \
	$$(foreach object,$$($(6)),$(5)/$$(object)) \
	$$(foreach dependency,$$($(8)),$(5)/$$(dependency)) \
	$(4) $$^ -o $$@
endef

# remote_include(name, path)
define remote_include
ifeq ($$(value VPATH),)
VPATH = $$(patsubst %/,%,$$(dir $(2)))
else
VPATH = $$(patsubst %/,%,$$(dir $(2))):$$(value VPATH)
endif

-include $(2)
endef

# make_directory(target, dependencies)
define make_directory
$(1): $(2)
	@test -d '$$@' || mkdir -p '$$@'
endef

