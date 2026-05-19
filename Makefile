# Makefile for Flux COBOL Constraint Engine
# Requires: GnuCOBOL (cobc)

COBC = cobc
CFLAGS = -free -x

COPYBOOKS = -I copybooks

PROGRAMS = FLXCHECK FLXFRACT FLXSEDIMNT FLXMAIN

.PHONY: all test clean

all: $(PROGRAMS)

FLXCHECK: FLXCHECK.cob copybooks/FLXCONST.cpy copybooks/FLXRESULT.cpy copybooks/FLXSEDIMNT.cpy
	$(COBC) $(CFLAGS) $(COPYBOOKS) -o $@ $<

FLXFRACT: FLXFRACT.cob copybooks/FLXCONST.cpy copybooks/FLXRESULT.cpy
	$(COBC) $(CFLAGS) $(COPYBOOKS) -o $@ $<

FLXSEDIMNT: FLXSEDIMNT.cob copybooks/FLXCONST.cpy copybooks/FLXRESULT.cpy copybooks/FLXSEDIMNT.cpy
	$(COBC) $(CFLAGS) $(COPYBOOKS) -o $@ $<

FLXMAIN: FLXMAIN.cob copybooks/FLXCONST.cpy copybooks/FLXRESULT.cpy copybooks/FLXSEDIMNT.cpy
	$(COBC) $(CFLAGS) $(COPYBOOKS) -o $@ $<

test: FLXMAIN
	./FLXMAIN

clean:
	rm -f $(PROGRAMS) *.o *.mod
