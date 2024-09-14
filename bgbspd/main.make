# Example Makefile that includes this file:
#
#    PACKAGE=bggit
#    BGBSPD_BUILD_DIR?=../bgbspd
#
#    WEB_IMAGES=$(wildcard src/*.svg)
#
#    include $(BGBSPD_BUILD_DIR)/main.make

UPLOADDIR=beej71@pdx1-shared-a1-06.dreamhost.com:~/beej.us/guide/$(PACKAGE)
STAGEDIR=./stage
BUILDTMP=./build_tmp

BGBS_THREADS?=8
MAKE_THREADS=-j $(BGBS_THREADS)

.PHONY: help all upload fastupload pristine clean

BOLD=$(shell tput bold)
RESET=$(shell tput sgr0)

help:
	@echo
	@echo "    $(BOLD)all$(RESET)          build everything"
	@echo "    $(BOLD)stage$(RESET)        copy everything to the staging area"
	@echo "    $(BOLD)clean$(RESET)        remove temporary build products"
	@echo "    $(BOLD)pristine$(RESET)     remove all build products"
	@echo "    $(BOLD)upload$(RESET)       pristine, all, stage, then upload results"
	@echo "    $(BOLD)fastupload$(RESET)   all, stage, then upload results"
	@echo

all:
	$(MAKE) $(MAKE_THREADS) -C src all
	$(MAKE) -C source clean

.PHONY: stage_build stage stage_html stage_translations stage_html_zips

stage_build:
	rm -rf $(STAGEDIR)
	mkdir -p $(STAGEDIR)/pdf
	mkdir -p $(STAGEDIR)/html
	mkdir -p $(STAGEDIR)/html/split
	mkdir -p $(STAGEDIR)/html/split-wide
	mkdir -p $(STAGEDIR)/translations
	mkdir -p $(STAGEDIR)/source

stage_books:
	cp -v website/* website/.htaccess $(STAGEDIR) || :
	cp -v src/$(PACKAGE)*.pdf $(STAGEDIR)/pdf
	cp -v src/$(PACKAGE).html $(STAGEDIR)/html/index.html
	cp -v src/$(PACKAGE)-wide.html $(STAGEDIR)/html/index-wide.html || :
ifdef WEB_IMAGES
	cp -v $(WEB_IMAGES) $(STAGEDIR)/html/ 2>/dev/null || :
endif

stage_translations:
	cp -v translations/*.pdf $(STAGEDIR)/translations 2>/dev/null || : 
	cp -v translations/*.html $(STAGEDIR)/translations 2>/dev/null || : 

stage_html_zips:
	mkdir -p $(STAGEDIR)/html/$(PACKAGE)
	cp -v src/split/* $(STAGEDIR)/html/$(PACKAGE)
	( cd $(STAGEDIR)/html; zip -r $(PACKAGE).zip $(PACKAGE); mv $(PACKAGE)/* split; rmdir $(PACKAGE) )
	mkdir -p $(STAGEDIR)/html/$(PACKAGE)
	cp -v src/split-wide/* $(STAGEDIR)/html/$(PACKAGE)
	( cd $(STAGEDIR)/html; zip -r $(PACKAGE)-wide.zip $(PACKAGE); mv $(PACKAGE)/* split-wide; rmdir $(PACKAGE) )

stage_examples:
	cp -rv source/* source/.htaccess $(STAGEDIR)/source || :
	mkdir -p $(BUILDTMP)/$(PACKAGE)_source
	cp -rv source/* source/.htaccess $(BUILDTMP)/$(PACKAGE)_source || :
	( cd $(BUILDTMP); zip -r $(PACKAGE)_source.zip $(PACKAGE)_source )
	cp -v $(BUILDTMP)/$(PACKAGE)_source.zip $(STAGEDIR)/source
	rm -rf $(BUILDTMP)

stage:
	$(MAKE) stage_build
	$(MAKE) stage_books
	$(MAKE) stage_translations
	$(MAKE) stage_html_zips
	$(MAKE) stage_examples

upload: pristine all stage
	rsync -rv -e ssh --delete $(STAGEDIR)/* $(STAGEDIR)/.htaccess $(UPLOADDIR)

fastupload: all stage
	rsync -rv -e ssh --delete $(STAGEDIR)/* $(STAGEDIR)/.htaccess $(UPLOADDIR)

pristine: clean
	rm -rf $(STAGEDIR)
	$(MAKE) -C src $@
	$(MAKE) -C source $@

clean:
	$(MAKE) -C src $@
	$(MAKE) -C source $@

