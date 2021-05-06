HOST_BUILD_DIR ?= $(BUILD_DIR_HOST)/$(PKG_NAME)$(if $(PKG_VERSION),-$(PKG_VERSION))

ifdef HOST_BUILD_PARALLEL
HOST_JOBS?=-j4
else
HOST_JOBS?=-j1
endif

include $(INCLUDE_DIR)/quilt.mk
include $(INCLUDE_DIR)/unpack.mk
include $(INCLUDE_DIR)/configure.mk

# build static tools
HOST_STATIC_LINKING ?= -static

HOST_MAKE_FLAGS =
HOST_MAKE_VARS = \
	CFLAGS="$(HOST_CFLAGS)" \
	LDFLAGS="$(HOST_STATIC_LINKING) $(HOST_LDFLAGS)"

.PHONY:dep unpack configure patch compile build install clean mostlyclean stampclean

install:compile
compile:patch
build:patch
patch:configure
configure:dep
dep:unpack

STAMP_UNPACKED:=$(HOST_BUILD_DIR)/.unpacked
STAMP_DEPENDED:=$(HOST_BUILD_DIR)/.depended
STAMP_CONFIGURED:=$(HOST_BUILD_DIR)/.configured
STAMP_PATCHED:=$(HOST_BUILD_DIR)/.patched
STAMP_COMPILED:=$(HOST_BUILD_DIR)/.compiled
STAMP_INSTALLED:=$(HOST_BUILD_DIR)/.installed

unpack:$(STAMP_UNPACKED)
dep:$(STAMP_DEPENDED)
configure:$(STAMP_CONFIGURED)
patch:$(STAMP_PATCHED)
compile:$(STAMP_COMPILED)
install:$(STAMP_INSTALLED)

define Build/Unpack
$(STAMP_UNPACKED):
	@-rm -rf $(HOST_BUILD_DIR)
	@mkdir -p $(HOST_BUILD_DIR)
ifdef Host/Unpack
	$(Host/Unpack)
else
	$(HOST_UNPACK)
endif
	@touch $$@
endef

define Build/Depend
$(STAMP_DEPENDED):
ifneq ($(strip $(HOST_BUILD_DEPENDS)),)
	$(foreach dep, $(HOST_BUILD_DEPENDS),
		$(MAKE) -C $(TOPDIR)/tools/$(dep) install \
	)
endif
	@touch $$@
endef

define Build/Configure
$(STAMP_CONFIGURED):
ifdef Host/Configure
	$(Host/Configure)
else
	$(call Host/Configure/Default)
endif
	@touch $$@
endef

define Build/Patch
$(STAMP_PATCHED):
	$(call Build/Patch/Default,$(HOST_BUILD_DIR))
	@touch "$$@"
endef

# always call make in build directory, use for patch development
define Build/CompileWithoutStamp
build:
	$(Host/PreCompile)
ifdef Host/Compile
	$(Host/Compile)
else
	$(MAKE) $(HOST_JOBS) -C $(HOST_BUILD_DIR) $(HOST_MAKE_FLAGS)
endif
endef

define Build/Compile
$(STAMP_COMPILED):
	$(Host/PreCompile)
ifdef Host/Compile
	$(Host/Compile)
else
	$(HOST_MAKE_VARS) \
	$(MAKE) $(HOST_JOBS) -C $(HOST_BUILD_DIR) $(HOST_MAKE_FLAGS)
endif
	@touch "$$@"
endef

define Build/Install
$(STAMP_INSTALLED):
ifdef HOST_MAKE_INSTALL
	$(HOST_MAKE_VARS) \
	$(MAKE) -C $(HOST_BUILD_DIR) $(HOST_MAKE_FLAGS) install
endif	
	$(Host/Install)
	@touch "$$@"
endef

define Build/Clean
clean:
	$(call Host/Clean)
	rm -rf $(HOST_BUILD_DIR)
endef

define Build/MostlyClean
mostlyclean:
	$(MAKE) clean -C $(HOST_BUILD_DIR)
	$(call Host/Clean)
	rm -rf $(STAMP_INSTALLED)
endef

stampclean:
	@rm -f $(STAMP_COMPILED)
	@rm -f $(STAMP_INSTALLED)

define HostBuild
$(Build/Unpack)
$(Build/Depend)
$(Build/Configure)
$(Build/Patch)
$(Build/Compile)
$(Build/CompileWithoutStamp)
$(Build/Install)
$(Build/Clean)
$(Build/MostlyClean)
endef
