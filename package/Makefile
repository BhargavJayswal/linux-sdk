curdir:=package

$(curdir)/subdirs := $(shell find $(curdir) -maxdepth 1 -type d)
$(curdir)/subdirs := $(filter-out $(curdir)/.svn,$($(curdir)/subdirs))
$(curdir)/subdirs := $(basename $(patsubst ./%,%,$($(curdir)/subdirs)))
$(curdir)/subdirs := $(filter-out $(curdir),$($(curdir)/subdirs))
$(curdir)/subdirs := $(sort $($(curdir)/subdirs))

$(curdir)/subtargets:=dep unpack configure patch compile build install clean mostlyclean stampclean

export PKG_BUILD_APP:=1

package/install:
	@for dir in $(package/subdirs) ; do \
        $(MAKE) -C $$dir install || exit "$$?"; \
    done

define Build/package
$(1)/$(2):
	+PKG_BUILD_TYPE=app $$(MAKE) -C $(1) $(2)
endef

$(foreach dir,$(package/subdirs), \
  $(foreach target,$(package/subtargets), \
    $(eval $(call Build/package,$(dir),$(target))) \
  ) \
)