include ../Makefile.defs

TESTS_DIR = \
    f2018-select-rank \
    flang-315421 \
    flang-325095 \
    flang-421111-3 \
    flang-444386-1 \
    flang-445999 \
    flang-446033a_loop \
    flang-446033a_ttdpd \
    flang-446033b_loop \
    flang-446033b_ttdpd \
    flang-446033c_loop \
    flang-446033d_loop \
    flang-463332 \
    flang-464541 \
    flang-469194 \
    flang-471982 \
    flang-476122a \
    flang-480581 \
    flang-485161 \
    flang-485265 \
    flang-491971 \
    flang-502486 \
    flang-505726 \
    flang-gpu-stop-integer \
    flang-gpu-stop-string \
    flang-gpu-exit \
    flang-gpu-abort \
    hellofort-io \
    mathdbl-tgt \
    mathquad-tgt \
    math-acos \
    math-erfc \
    olcf-tf-7-loop-combined \
    rocm-aomp-issue-842 \
    rocm-aomp-issue-1148 \
    rocm-issue-201 \
    rocm-issue-208 \
    rocm-issue-241 \
    split-dist-f90 \
    split-dist-par-c \
    split-dist-par-f90 \
    tgt-print \
    tgt-printf-c \
    tgt-stop \
    tgt-write

all:
	@for test_dir in $(TESTS_DIR); do \
	  echo; \
	  test_name=`grep "TESTNAME *=" $$test_dir/Makefile | sed "s/.*= *//"`; \
	  echo "TEST_DIR: $$test_dir\tTEST_NAME: $$test_name\tMAKE: $(MAKE) -C $$test_dir"; \
	  $(MAKE) -C $$test_dir; \
	done

run run_obin run_sbin run_llbin clean clean_log llbin sbin obin:
	@for test_dir in $(TESTS_DIR); do \
	  echo $$nnn; \
	  test_name=`grep "TESTNAME *=" $$test_dir/Makefile | sed "s/.*= *//"`; \
	  echo "TEST_DIR: $$test_dir\tTEST_NAME: $$test_name\tMAKE: $(MAKE) -C $$test_dir $@"; \
	  $(MAKE) -C $$test_dir $@; \
	done

check:
	 @for test_dir in $(TESTS_DIR); do \
          echo $$nnn; \
          test_name=`grep "TESTNAME *=" $$test_dir/Makefile | sed "s/.*= *//"`; \
          echo "TEST_DIR: $$test_dir\tTEST_NAME: $$test_name\tMAKE: $(MAKE) -C $$test_dir $@"; \
          $(MAKE) -C $$test_dir $@; \
        done

.ll .ll.s .ll.o .s .s.o .o:
	@for test_dir in $(TESTS_DIR); do \
	  echo $$nnn; \
	  test_name=`grep "TESTNAME *=" $$test_dir/Makefile | sed "s/.*= *//"`; \
	  echo "TEST_DIR: $$test_dir\tTEST_NAME: $$test_name\tMAKE: $(MAKE) -C $$test_dir $$test_name$@"; \
	  $(MAKE) -C $$test_dir $$test_name$@; \
	done

help:
	@echo 
	@echo "LLVM Tool Chain:	$(AOMP)/bin"
	@echo "Offload Targets:	$(TARGET)"
	@echo "Host Target:		$(AOMP_CPUTARGET)"
	@echo "Application Dirs:	$(TESTS_DIR)"
	@echo 
	@echo "This Makefile supports the following flags:"
	@echo 
	@echo "	make llbin      // Link pass only"
	@echo "	make run_llbin  // Execute llbin"
	@echo 
	@echo "	make sbin       // Link pass only"
	@echo "	make run_sbin   // Execute sbin"
	@echo 
	@echo "	make obin       // Link pass only"
	@echo "	make run_obin   // Execute obin"
	@echo 
	@echo "	make .ll        // Compile pass only             : -c -S -emit-llvm"
	@echo "	make .ll.s      // Backend pass only             : -c -S"
	@echo "	make .ll.o      // Assemble pass only            : -c"
	@echo "	make .s         // Compile & Backend passes      : -c -S"
	@echo "	make .s.o       // Assemble pass only            : -c"
	@echo "	make .o         // Compile, Backend, Assemble    : -c"
	@echo 
	@echo "	make            // All passes, build all examples from Application Dirs"
	@echo "	make run        // Execute all binaries from Application Dirs"
	@echo 
	@echo "	make clean"
	@echo "	make clean_log"
	@echo "	make help"
	@echo 
	@echo " Environment variables to control compilation & execution"
	@echo "    VERBOSE=1        See lots of compiler messages and driver actions"
	@echo "    TEMPS=1          Do not delete intermediate files"
	@echo "    OFFLOAD_DEBUG=1  See Runtime diagnostics for each call to libomptarget API"
	@echo "    TARGET=          Override Makefile target"
	@echo
	@echo " Compile Environment:  $(SETENV)"
	@echo
	@echo " Run Environment:      $(RUNENV)"
	@echo
	@echo " Compile Flags:        $(CFLAGS) $(EXTRA_CFLAGS)"
	@echo
	@echo " OMP Compile Flags:    $(OMP_FLAGS) $(EXTRA_OMP_FLAGS)"
	@echo
	@echo " Link Flags:           $(LINK_FLAGS) $(EXTRA_LDFLAGS)"
	@echo
