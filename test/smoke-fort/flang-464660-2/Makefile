NOOPT        = 1
include ../../Makefile.defs

TESTNAME     = flang-464660
TESTSRC_MAIN = flang-464660.f90
TESTSRC_AUX  =
TESTSRC_ALL  = $(TESTSRC_MAIN) $(TESTSRC_AUX)

FLANG        ?= flang-new
OMP_BIN      = $(AOMP)/bin/$(FLANG)
CC           = $(OMP_BIN) $(VERBOSE)
OMP_FLAGS   += -lflang_rt.hostdevice
#-ccc-print-phases
#"-\#\#\#"

include ../Makefile.rules
