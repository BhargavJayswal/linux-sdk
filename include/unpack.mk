ifneq ($(strip $(PKG_SOURCE)),)

ifdef PKG_UNPACK_DIR_OVERRIDE
TAR_CMD=tar -C $(1) -xf - --strip-components=1
else
TAR_CMD=tar -C $(1)/.. -xf -
endif

UNZIP_CMD=unzip -d $(1)/.. $(TARBALL_DIR)/$(PKG_SOURCE)

ext=$(word $(words $(subst ., ,$(1))),$(subst ., ,$(1)))

EXT:=$(call ext,$(PKG_SOURCE))
EXT1:=$(EXT)

ifeq ($(filter gz tgz,$(EXT)),$(EXT))
      EXT:=$(call ext,$(PKG_SOURCE:.$(EXT)=))
      DECOMPRESS_CMD:=gzip -dc $(TARBALL_DIR)/$(PKG_SOURCE) |
endif
ifeq ($(filter bzip2 bz2 bz tbz2 tbz,$(EXT)),$(EXT))
      EXT:=$(call ext,$(PKG_SOURCE:.$(EXT)=))
      DECOMPRESS_CMD:=bzcat $(TARBALL_DIR)/$(PKG_SOURCE) |
endif
ifeq ($(filter xz txz,$(EXT)),$(EXT))
      EXT:=$(call ext,$(PKG_SOURCE:.$(EXT)=))
      DECOMPRESS_CMD:=xzcat $(TARBALL_DIR)/$(PKG_SOURCE) |
endif
ifeq ($(filter tgz tbz tbz2 txz,$(EXT1)),$(EXT1))
      EXT:=tar
endif
DECOMPRESS_CMD ?= cat $(TARBALL_DIR)/$(PKG_SOURCE) |
ifeq ($(EXT),tar)
      UNPACK_CMD=$(DECOMPRESS_CMD) $(TAR_CMD)
endif
ifeq ($(EXT),cpio)
      UNPACK_CMD=$(DECOMPRESS_CMD) (cd $(1)/..; cpio -i -d)
endif
ifeq ($(EXT),zip)
      UNPACK_CMD=$(UNZIP_CMD)
endif

endif

ifdef PKG_BUILD_DIR
  PKG_UNPACK ?= $(call UNPACK_CMD,$(PKG_BUILD_DIR))
endif

ifdef HOST_BUILD_DIR
  HOST_UNPACK ?= $(call UNPACK_CMD,$(HOST_BUILD_DIR))
endif