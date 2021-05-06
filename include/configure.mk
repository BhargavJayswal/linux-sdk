CONFIGURE_CMD = ./configure

CONFIGURE_ARGS =--host=$(GNU_TARGET_NAME)\
		--prefix=/usr

CONFIGURE_VARS = \
		$(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS)" \
		CPPFLAGS="$(TARGET_CPPFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)"

HOST_CONFIGURE_VARS = \
	CC="$(HOSTCC)" \
	CFLAGS="$(HOST_CFLAGS)" \
	CPPFLAGS="$(HOST_CPPFLAGS)" \
	LDFLAGS="$(HOST_LDFLAGS)"

HOST_CONFIGURE_ARGS = \
	--program-prefix="" \
	--program-suffix="" \
	--prefix=$(STAGING_DIR_HOST) \
	--exec-prefix=$(STAGING_DIR_HOST) \
	--sysconfdir=$(STAGING_DIR_HOST)/etc \
	--localstatedir=$(STAGING_DIR_HOST)/var \
	--sbindir=$(STAGING_DIR_HOST)/bin

define Build/Configure/Default
       cd $(PKG_BUILD_DIR); \
       if [ -x $(CONFIGURE_CMD) ]; then \
		$(CONFIGURE_VARS) \
		$(2) \
		$(CONFIGURE_CMD) \
		$(CONFIGURE_ARGS) \
		$(1); \
	fi;
endef

define Host/Configure/Default
       cd $(HOST_BUILD_DIR); \
       if [ -x $(CONFIGURE_CMD) ]; then \
		$(HOST_CONFIGURE_VARS) \
		$(2) \
		$(CONFIGURE_CMD) \
		$(HOST_CONFIGURE_ARGS) \
		$(1); \
	fi;
endef