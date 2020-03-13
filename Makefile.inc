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
SANITIZERS = integer bounds
SANITIZER_TYPE = address safe-stack

## Clang coverage
COVERAGE = -fprofile-instr-generate -fcoverage-mapping

## Assign the cflags and ldflags for libfuzzer
INTERNAL_CFLAGS  = $(FUZZ_CFLAGS) -fsanitize=$(subst $(space),$(comma),$(SANITIZERS))
INTERNAL_LDFLAGS = $(FUZZ_LDFLAGS) -fsanitize=$(subst $(space),$(comma),$(SANITIZERS))

## Define some utility macros for helping out with dependencies
MAKEDIR_PREFIX := $(realpath $(MAKEDIR))/

# setcompiler(compile-var, name, pattern)
define setcompiler
$$(eval $$(call compile,$(1),%.$$(OBJEXT),$(3),,$$($(2)_VPATH)))
endef

# setlinker(link-var, name, ladds)
define setlinker
$$(eval $$(call link,$(1),%.fuzzer,%.o,$(3),$$(realpath $$($(2)_VPATH)),$(2)_OBJECTS,$(2)_LDADD,$(2)_DEPENDENCIES))

$(foreach sanitizer,$(SANITIZER_TYPE),$$(eval $$(call link,$(1),%.$(sanitizer),%.o,-fsanitize=$(sanitizer) $(3),$$(realpath $$($(2)_VPATH)),$(2)_OBJECTS,$(2)_LDADD,$(2)_DEPENDENCIES)))
endef

# compile(compile-var, target, cdeps, cadds, rbase)
define compile
$(2): $(3)
	cd '$(5)' && $$($(1)) $$(INTERNAL_CFLAGS) $(4) -o '$$(MAKEDIR_PREFIX)$$@' -c '$$(MAKEDIR_PREFIX)$$<'
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

# autoinclude(name, path)
define autoinclude
ifeq ($$(value VPATH),)
VPATH = $$(patsubst %/,%,$$(dir $(2)))
else
VPATH = $$(patsubst %/,%,$$(dir $(2))):$$(value VPATH)
endif

-include $(2)

$(foreach sanitizer,$(SANITIZER_TYPE),$$(eval $$(call autobuild,$(1).$(sanitizer),$(dir $(2)),$$(INTERNAL_CFLAGS) -fsanitize=$(sanitizer),$$(INTERNAL_LDFLAGS) -fsanitize=$(sanitizer))))
endef

# autobuild(name, path, cflags, ldflags)
define autobuild
.PHONY: $(1)
$(1): $$(patsubst %/,%,$(2))
	$$(MAKE) -B -C "$$<" CFLAGS="$(3)" CXXFLAGS="$(3)" LDFLAGS="$(4)"
endef

# make_directory(target, dependencies)
define make_directory
$(1): $(2)
	@test -d '$$@' || mkdir -p '$$@'
endef
