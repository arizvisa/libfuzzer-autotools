include Makefile.config

# After running ./configure with CC=clang and CXX=clang++, use make to build
# your target with CFLAGS and CXXFLAGS set to the following:
CFLAGS = -g -fno-omit-frame-pointer -O2 -fsanitize=fuzzer,address
CXXFLAGS = -g -fno-omit-frame-pointer -O2 -fsanitize=fuzzer,address

%.o: %.c
	$(COMPILE) -o $@ -c $<

%.o: %.cc
	$(CXXCOMPILE) -o $@ -c $<

%.fuzzer: %.o
	$(CXXLINK) $(foreach libpath,$(LIBPATH),-L$(libpath)/.libs) $(foreach lib,$(LIBS),-l$(lib)) $^
	-mkdir $(basename $@).corpus
	-mkdir $(basename $@).crash
