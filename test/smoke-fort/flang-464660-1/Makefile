include ../../Makefile.defs

TESTNAME     = flang-464660-1
TESTSRC_MAIN = flang-464660-1.f90
TESTSRC_ALL  =  $(TESTSRC_AUX) $(TESTSRC_MAIN)

FLANG        ?= flang-new
CLANG        ?= clang
OMP_BIN      ?= $(AOMP)/bin/$(FLANG)
CC           = $(OMP_BIN) $(VERBOSE)

include ../Makefile.rules

flang-464660-1: $(TESTSRC_ALL)
	$(CC) $(OMP_FLAGS) -O2 -c flang-464660-1.f90
	$(AOMP)/bin/$(CLANG) -lm -L$(AOMP)/lib -lflang_rt.runtime -lomp -lomptarget $(OMP_FLAGS) -o $@ flang-464660-1.o
