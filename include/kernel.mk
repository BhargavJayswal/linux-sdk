PATCH_DIR ?= patches-$(KERNEL_PATCHVER)
FILES_DIR ?= $(foreach dir,$(wildcard ./files ./files-$(KERNEL_PATCHVER)),"$(dir)")

GENERIC_PLATFORM_DIR := $(TOPDIR)/package/linux/generic
GENERIC_PATCH_DIR := $(GENERIC_PLATFORM_DIR)/patches-$(KERNEL_PATCHVER)
GENERIC_FILES_DIR := $(foreach dir,$(wildcard $(GENERIC_PLATFORM_DIR)/files $(GENERIC_PLATFORM_DIR)/files-$(KERNEL_PATCHVER)),"$(dir)")

LZMA_CMD := $(HOST_BIN_DIR)/lzma
CMD_RBTIMAGE := $(HOST_BIN_DIR)/rbtimage

include $(INCLUDE_DIR)/quilt.mk
include $(INCLUDE_DIR)/unpack.mk

PKG_BUILD_DIR ?= $(BUILD_DIR)/$(PKG_NAME)$(if $(PKG_VERSION),-$(PKG_VERSION))
LINUX_DIR = $(PKG_BUILD_DIR)

KERNEL_MAKEOPTS := -j4 -C $(PKG_BUILD_DIR) \
	CROSS_COMPILE="$(TARGET_CROSS)" \
	ARCH="$(ARCH)"

.PHONY: unpack configure patch compile build install clean mostlyclean stampclean menuconfig

install:compile
compile:patch
patch:configure
configure:unpack

STAMP_UNPACKED:=$(PKG_BUILD_DIR)/.unpacked
STAMP_CONFIGURED:=$(PKG_BUILD_DIR)/.configured
STAMP_PATCHED:=$(PKG_BUILD_DIR)/.patched
STAMP_COMPILED:=$(PKG_BUILD_DIR)/.compiled
STAMP_INSTALLED:=$(PKG_BUILD_DIR)/.installed

unpack:$(STAMP_UNPACKED)
configure:$(STAMP_CONFIGURED)
patch:$(STAMP_PATCHED)
compile:$(STAMP_COMPILED)
install:$(STAMP_INSTALLED)

menuconfig:
	$(MAKE) $(KERNEL_MAKEOPTS) menuconfig

modules:
	$(MAKE) $(KERNEL_MAKEOPTS) modules	
	$(call Kernel/Modules/Install)

stampclean:
	@rm -f $(STAMP_COMPILED)
	@rm -f $(STAMP_INSTALLED)

initramfsclean:
	@rm -f $(LINUX_DIR)/usr/initramfs_data.cpio

build: stampclean initramfsclean install

define Kernel/Unpack
$(STAMP_UNPACKED):
	@-rm -rf $(PKG_BUILD_DIR)
	@mkdir -p $(PKG_BUILD_DIR)
	$(PKG_UNPACK)
	@touch $$@
endef

ifneq ($(CONFIG_INITRAMFS_ENABLE),)
INITRAMFS_EXTRA_FILES ?= $(INCLUDE_DIR)/device.txt
define Kernel/Initramfs/Configure
	mv $(LINUX_DIR)/.config $(LINUX_DIR)/.config.old
	grep -v -e INITRAMFS -e CONFIG_RD_ -e CONFIG_BLK_DEV_INITRD $(LINUX_DIR)/.config.old > $(LINUX_DIR)/.config
	echo 'CONFIG_BLK_DEV_INITRD=y' >> $(LINUX_DIR)/.config
	echo 'CONFIG_INITRAMFS_SOURCE="$(strip $(TARGET_DIR) $(INITRAMFS_EXTRA_FILES))"' >> $(LINUX_DIR)/.config
	echo 'CONFIG_INITRAMFS_ROOT_UID=$(shell id -u)' >> $(LINUX_DIR)/.config
	echo 'CONFIG_INITRAMFS_ROOT_GID=$(shell id -g)' >> $(LINUX_DIR)/.config
	echo 'CONFIG_INITRAMFS_COMPRESSION_NONE=y' >> $(LINUX_DIR)/.config
	echo -e '# CONFIG_INITRAMFS_COMPRESSION_GZIP is not set\n# CONFIG_RD_GZIP is not set' >> $(LINUX_DIR)/.config
	echo -e '# CONFIG_INITRAMFS_COMPRESSION_BZIP2 is not set\n# CONFIG_RD_BZIP2 is not set' >> $(LINUX_DIR)/.config
	echo -e '# CONFIG_INITRAMFS_COMPRESSION_LZMA is not set\n# CONFIG_RD_LZMA is not set' >> $(LINUX_DIR)/.config
	echo -e '# CONFIG_INITRAMFS_COMPRESSION_LZO is not set\n# CONFIG_RD_LZO is not set' >> $(LINUX_DIR)/.config
	echo -e '# CONFIG_INITRAMFS_COMPRESSION_XZ is not set\n# CONFIG_RD_XZ is not set' >> $(LINUX_DIR)/.config
	echo -e '# CONFIG_INITRAMFS_COMPRESSION_LZ4 is not set\n# CONFIG_RD_LZ4 is not set' >> $(LINUX_DIR)/.config
endef
else
define Kernel/Initramfs/Configure
	mv $(LINUX_DIR)/.config $(LINUX_DIR)/.config.old
	grep -v INITRAMFS $(LINUX_DIR)/.config.old > $(LINUX_DIR)/.config
	echo 'CONFIG_INITRAMFS_SOURCE=""' >> $(LINUX_DIR)/.config
endef
endif

define Kernel/Configure
$(STAMP_CONFIGURED):
	cp -rf config $(PKG_BUILD_DIR)/.config
	$(call Kernel/Initramfs/Configure)
	[ -d $(LINUX_DIR)/user_headers ] || $(MAKE) $(KERNEL_MAKEOPTS) INSTALL_HDR_PATH=$(LINUX_DIR)/user_headers headers_install
	@touch $$@
endef

define Kernel/Patch
$(STAMP_PATCHED):
	$(Kernel/Patch/Default)
	@touch "$$@"
endef

define Kernel/Compile
$(STAMP_COMPILED):
	+$(MAKE) $(KERNEL_MAKEOPTS)
	@touch "$$@"
endef

define Kernel/DeviceTree/Install
	+$(MAKE) $(KERNEL_MAKEOPTS) dtbs
endef

define Kernel/Modules/Install
	$(INSTALL_DIR) $(TARGET_DIR)/lib/modules/$(PKG_VERSION)
	$(foreach ko, $(MODULES_INSTALL),
		$(CP) $(PKG_BUILD_DIR)/$(ko) $(TARGET_DIR)/lib/modules/$(PKG_VERSION) \
	)
endef

OBJCOPY_STRIP = -R .reginfo -R .notes -R .note -R .comment -R .mdebug -R .note.gnu.build-id
define Kernel/Install
$(STAMP_INSTALLED):
	$(call Kernel/Modules/Install)
	@touch "$$@"
endef

define Kernel/Clean
clean:
	rm -rf $(PKG_BUILD_DIR)
endef

define BuildKernel
$(Kernel/Unpack)
$(Kernel/Configure)
$(Kernel/Patch)
$(Kernel/Compile)
$(Kernel/Install)
$(Kernel/Clean)
endef
