PKG_BUILD_DIR ?= $(BUILD_DIR)/$(PKG_NAME)$(if $(PKG_VERSION),-$(PKG_VERSION))
PKG_INSTALL_DIR ?= $(PKG_BUILD_DIR)/install_dir
APP_INSTALL_DIR ?= $(PKG_BUILD_DIR)/rpkg_dir
PKG_DESC ?= $(PKG_NAME)
ifdef PKG_BUILD_PARALLEL
PKG_JOBS?=-j4
else
PKG_JOBS?=-j1
endif

include $(INCLUDE_DIR)/quilt.mk
include $(INCLUDE_DIR)/unpack.mk
include $(INCLUDE_DIR)/configure.mk

.PHONY:dep unpack configure patch compile build install app_install clean mostlyclean stampclean menuconfig

build: stampclean install
install:compile
ifdef PKG_PATCH_BEFORE_CONFIGURE
compile:configure
configure:patch
patch:dep
dep:unpack
else
compile:patch
patch:configure
configure:dep
dep:unpack
endif

STAMP_UNPACKED:=$(PKG_BUILD_DIR)/.unpacked
STAMP_DEPENDED:=$(PKG_BUILD_DIR)/.depended
STAMP_CONFIGURED:=$(PKG_BUILD_DIR)/.configured
STAMP_PATCHED:=$(PKG_BUILD_DIR)/.patched
STAMP_COMPILED:=$(PKG_BUILD_DIR)/.compiled
STAMP_INSTALLED:=$(PKG_BUILD_DIR)/.installed

unpack:$(STAMP_UNPACKED)
dep:$(STAMP_DEPENDED)
configure:$(STAMP_CONFIGURED)
patch:$(STAMP_PATCHED)
compile:$(STAMP_COMPILED)
install:$(STAMP_INSTALLED)

define Build/Unpack
$(STAMP_UNPACKED):
	@-rm -rf $(PKG_BUILD_DIR)
	@mkdir -p $(PKG_BUILD_DIR)
ifdef Package/Unpack
	$(Package/Unpack)
else
	$(PKG_UNPACK)
endif
	@touch $$@
endef

define Build/Depend
$(STAMP_DEPENDED):
ifneq ($(strip $(PKG_BUILD_DEPENDS)),)
	$(foreach dep, $(PKG_BUILD_DEPENDS),
		@echo -e "\033[32m> Building dependent package $(dep) ......\033[0m" && BUILD_DEPENDS=true $(MAKE) -C $(TOPDIR)/package/$(dep) install \
	)
endif
	@touch $$@
endef

define Build/Configure
$(STAMP_CONFIGURED):
ifdef Package/Configure
	$(Package/Configure)
else
	$(call Build/Configure/Default)
endif
	@touch $$@
endef

define Build/Patch
$(STAMP_PATCHED):
ifdef Package/Patch
	$(Package/Patch)
else
	$(call Build/Patch/Default,$(PKG_BUILD_DIR))
endif
	@touch "$$@"
endef

define Build/Compile
$(STAMP_COMPILED):
	$(Package/PreCompile)
ifdef Package/Compile
	$(Package/Compile)
else
	$(MAKE_VARS) \
	$(MAKE) $(PKG_JOBS) -C $(PKG_BUILD_DIR) $(MAKE_FLAGS)
endif
	@touch "$$@"
endef

define Build/Rpkg
	@$(RSTRIP) $(APP_INSTALL_DIR)
	mkdir -p $(APP_INSTALL_DIR)/CONTROL
	( \
		echo "Package: $(PKG_NAME)"; \
		echo "Description: $(PKG_DESC)"; \
		echo "Version: $(PKG_VERSION)"; \
		echo "Platform: $(PLATFORM)"; \
		echo "Architecture: $(ARCH)"; \
 	) > $(APP_INSTALL_DIR)/CONTROL/control
	chmod 644 $(APP_INSTALL_DIR)/CONTROL/control
	$(INCLUDE_DIR)/rpkg-build.sh -c -o 0 -g 0 $(APP_INSTALL_DIR) $(PKG_BUILD_DIR)
ifeq ($(PKG_BUILD_VER),)
	$(HOST_BIN_DIR)/rbtimage -s -T package -P $(PLATFORM) -n $(PKG_NAME) -V $(PKG_VERSION) -d $(PKG_BUILD_DIR)/$(PKG_NAME)_$(PKG_VERSION)_$(PLATFORM).rpk $(PACKAGE_DIR)/$(PLATFORM)-$(PKG_NAME)-$(PKG_VERSION).rpk
else
	$(HOST_BIN_DIR)/rbtimage -s -T package -P $(PLATFORM) -n $(PKG_NAME) -V $(PKG_VERSION) -d $(PKG_BUILD_DIR)/$(PKG_NAME)_$(PKG_VERSION)_$(PLATFORM).rpk $(PACKAGE_DIR)/$(PLATFORM)-$(PKG_NAME)-$(PKG_VERSION).$(PKG_BUILD_VER).rpk
endif
endef

define Build/Install
app_install:
	$(call Package/Install,$(APP_INSTALL_DIR))

$(STAMP_INSTALLED):
ifdef PKG_MAKE_INSTALL
	$(MAKE_VARS) \
	$(MAKE) -C $(PKG_BUILD_DIR) $(MAKE_FLAGS) DESTDIR=$(PKG_INSTALL_DIR) install
endif
	$(call Package/Install/Develop,$(STAGING_DIR))
ifeq ($(PKG_BUILD_TYPE),app)
	$(call Package/Install,$(APP_INSTALL_DIR))
ifneq ($(strip $(PKG_INSTALL_DEPENDS)),)
	$(foreach dep, $(PKG_INSTALL_DEPENDS),
		APP_INSTALL_DIR=$(APP_INSTALL_DIR) $(MAKE) -C $(TOPDIR)/package/$(dep) app_install \
	)
endif
ifeq ($(BUILD_DEPENDS),)
	PKG_BUILD_DIR=$(PKG_BUILD_DIR) $(INCLUDE_DIR)/web_language_js_gen
	$(call Build/Rpkg)
endif
else ifeq ($(PKG_BUILD_TYPE),tarball)
	$(call Package/Install)
else
	$(call Package/Install,$(STAGING_ROOTFS_DIR))
endif	
	@touch "$$@"
endef

define Build/Clean
clean:
	rm -rf $(PKG_BUILD_DIR)
endef

define Build/MostlyClean
mostlyclean:
ifdef Package/MostlyClean
	$(Package/MostlyClean)
else
	$(MAKE) clean -C $(PKG_BUILD_DIR)
endif
	@rm -rf $(STAMP_COMPILED)
	@rm -rf $(STAMP_INSTALLED)
endef

menuconfig:
	$(MAKE_VARS) \
	$(MAKE) $(PKG_JOBS) -C $(PKG_BUILD_DIR) $(MAKE_FLAGS) menuconfig

stampclean:
	@rm -f $(STAMP_COMPILED)
	@rm -f $(STAMP_INSTALLED)

define BuildPackage
$(Build/Unpack)
$(Build/Depend)
$(Build/Configure)
$(Build/Patch)
$(Build/Compile)
$(Build/Install)
$(Build/Clean)
$(Build/MostlyClean)
endef
