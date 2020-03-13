ifeq ($(MAKEDIR),)
    $(error Please do not use this file directly as it is intended to be included)
endif

## Simple utilities for enabling some GNU-specific Makefile trickery
noop=
space=$(noop) $(noop)
comma=,
lc = $(subst A,a,$(subst B,b,$(subst C,c,$(subst D,d,$(subst E,e,$(subst F,f,$(subst G,g,$(subst H,h,$(subst I,i,$(subst J,j,$(subst K,k,$(subst L,l,$(subst M,m,$(subst N,n,$(subst O,o,$(subst P,p,$(subst Q,q,$(subst R,r,$(subst S,s,$(subst T,t,$(subst U,u,$(subst V,v,$(subst W,w,$(subst X,x,$(subst Y,y,$(subst Z,z,$1))))))))))))))))))))))))))

define coerce_boolean
$(patsubst n%,0,$(patsubst y%,1,$(patsubst f%,0,$(patsubst t%,1,$(patsubst off,0,$(patsubst on,1,$(filter n no y yes f false t true off on,$(call lc,$(1)))))))))
endef

define enabled
$(if $(filter-out 0 1,$(call coerce_boolean,$(1))),$(error unexpected non-boolean value ($(1))),$(call coerce_boolean,$(1)))
endef

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
