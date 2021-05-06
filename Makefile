TOPDIR:=${CURDIR}
export TOPDIR

# the default target
all:

include rules.mk

ifeq ($(ARCH),)
$(error ARCH not defined)
endif
ifeq ($(PLATFORM),)
$(error PLATFORM not defined)
endif

unexport LPATH

MAKE:=make

STAMP_PREPARE:=$(STAGING_DIR)/.prepared
STAMP_TOOLS:=$(STAGING_DIR_BASE)/.tools_prepared
PREPARED?=$(shell if [ -f $(STAMP_PREPARE) ]; then echo "yes"; else echo "no"; fi;)

ifeq ($(strip $(PREPARED)),no)
  override PREPARED=yes
  export PREPARED

  clean deepclean:
	@$(MAKE) $@

  %::
	@$(MAKE) prepare
	$(MAKE) $@

else  
  include package/Makefile
  include tools/Makefile
  
  prepare: $(STAMP_PREPARE) $(STAMP_TOOLS)
  $(STAMP_PREPARE): dir_prepare
	@touch $@
	
  $(STAMP_TOOLS): tools/install
	@touch $@ 
 
  dir_prepare:
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(PACKAGE_DIR)

all: package/install
	@echo build complete

clean: FORCE
	rm -rf $(BUILD_DIR) $(BIN_DIR)

endif