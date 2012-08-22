# CoLoR, a Coq library on rewriting and termination.
# See the COPYRIGHTS and LICENSE files.
#
# - Frederic Blanqui, 2005-02-03

.SUFFIXES:

.PHONY: clean clean-all clean-doc default config dist doc install-dist install-doc tags all

MAKECOQ := $(MAKE) -r -f Makefile.coq -j 3 OTHERFLAGS="-dont-load-proofs"

VFILES := $(shell find . -name \*.v)

default: Makefile.coq
	$(MAKECOQ)

config Makefile.coq:
	coq_makefile -R . CoLoR $(VFILES) > Makefile.coq
	$(MAKECOQ) depend

clean:
	rm -f `find . -name \*~`
	$(MAKECOQ) clean

clean-all: clean
	rm -f Makefile.coq

clean-doc:
	rm -f doc/CoLoR.*.html doc/index.html doc/main.html

tags:
	coqtags `find . -name \*.v`

doc:
	coqdoc --html -g -d doc -R . CoLoR `find . -path ./Coccinelle -prune -o -name \*.v -print`
	./createIndex

ADR := ~/rewriting-svn/web/formes/color
LOCAL := ~/rewriting-svn/web/color/site

install-doc:
	cp doc/coqdoc.css doc/*.html $(ADR)/doc
	cp doc/coqdoc.css doc/*.html $(LOCAL)/doc

dist:
	./createDist

install-dist:
	cp CoLoR_`date +%y%m%d`.tar.gz $(ADR)/CoLoR.tar.gz
	cp CHANGES $(ADR)/CHANGES.CoLoR
	cp CHANGES $(LOCAL)/CHANGES.CoLoR

%.vo: %.v
	$(MAKECOQ) $@

%:
	$(MAKECOQ) $@
