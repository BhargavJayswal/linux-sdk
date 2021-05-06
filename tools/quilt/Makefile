include $(TOPDIR)/rules.mk

PKG_NAME:=quilt
PKG_VERSION:=0.63

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz

HOST_BUILD_DIR:=$(BUILD_DIR_HOST)/$(PKG_NAME)-$(PKG_VERSION)

#HOST_MAKE_INSTALL:=1

include $(INCLUDE_DIR)/host-build.mk

define Host/Configure
	cd $(HOST_BUILD_DIR) && autoconf
	$(call Host/Configure/Default)
	[ -f $(HOST_BUILD_DIR)/Makefile ]
endef

define Host/Compile
	$(MAKE) -C $(HOST_BUILD_DIR) all
endef

define Host/Install
	$(MAKE) -C $(HOST_BUILD_DIR) install
endef

define Host/Clean
	rm -f $(STAGING_DIR_HOST)/bin/quilt
endef

$(eval $(call HostBuild))
