## Clang sanitizers
COVERAGE = -fprofile-instr-generate -fcoverage-mapping
SANITIZERS = integer bounds

## Assign the cflags and ldflags for libfuzzer
INTERNAL_CFLAGS  = $(FUZZ_CFLAGS) -fsanitize=$(subst $(space),$(comma),$(SANITIZERS))
INTERNAL_LDFLAGS = $(FUZZ_LDFLAGS) -fsanitize=$(subst $(space),$(comma),$(SANITIZERS))

## Define some utility macros for helping out with dependencies
MAKEDIR_PREFIX := $(realpath $(MAKEDIR))/

# setcompiler(compile-var, name, pattern)
define setcompiler
%.$$(OBJEXT): $(3)
	cd '$($(2)_VPATH)' && $$($(1)) $$(INTERNAL_CFLAGS) -o '$$(MAKEDIR_PREFIX)$$@' -c '$$(MAKEDIR_PREFIX)$$<'
endef

# setlinker(link-var, name, ladds)
define setlinker
%.fuzzer: %.o
	cd '$($(2)_VPATH)' && $$($(1)) $$(INTERNAL_LDFLAGS) \
	$$(foreach item,$$($(2)_LDADD),$$(if $$(filter-out -%,$$(item)),$(realpath $($(2)_VPATH))/$$(item),$$(item))) \
	$$(foreach object,$$($(2)_OBJECTS),$(realpath $($(2)_VPATH))/$$(object)) \
	$$(foreach object,$$($(2)_DEPENDENCIES),$(realpath $($(2)_VPATH))/$$(object)) \
	$(3) $$(addprefix $$(MAKEDIR_PREFIX),$$^) -o '$$(MAKEDIR_PREFIX)$$@'
endef

# link(link-var, target, ldeps, ladds, rbase, robjs-var, radds-var, rdeps-var)
define link
$(2): $(3)
	cd '$(5)' && $$($(1)) $$(INTERNAL_LDFLAGS) \
	$$(foreach item,$$($(7)),$$(if $$(filter-out -%,$$(item)),$(5)/$$(item),$$(item))) \
	$$(foreach object,$$($(6)),$(5)/$$(object)) \
	$$(foreach dependency,$$($(8)),$(5)/$$(dependency)) \
	$(4) $$(addprefix $$(MAKEDIR_PREFIX),$$^) -o '$$(MAKEDIR_PREFIX)$$@'
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
