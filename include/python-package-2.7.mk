
PYTHON_VERSION=2.7
PYTHON_DIR:=$(STAGING_DIR)/usr
PYTHON_BIN_DIR:=$(PYTHON_DIR)/bin
PYTHON_INC_DIR:=$(PYTHON_DIR)/include/python$(PYTHON_VERSION)
PYTHON_LIB_DIR:=$(PYTHON_DIR)/lib/python$(PYTHON_VERSION)

PYTHON:=$(PYTHON_BIN_DIR)/python

PYTHON_PKG_DIR:=/usr/lib/python$(PYTHON_VERSION)/site-packages

define Build/Compile/PyMod
    ( cd $(PKG_BUILD_DIR)/$(1); \
		$(TARGET_CONFIGURE_OPTS) \
		LDSHARED="$(TARGET_CC) -shared" \
		CFLAGS="$(TARGET_CFLAGS)" \
		CPPFLAGS="$(TARGET_CPPFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)" \
		$(3) \
		python ./setup.py $(2) \
    );
endef