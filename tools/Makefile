curdir:=tools

$(curdir)/subdirs := $(shell find $(curdir) -maxdepth 1 -type d)
$(curdir)/subdirs := $(filter-out $(curdir)/.svn,$($(curdir)/subdirs))
$(curdir)/subdirs := $(basename $(patsubst ./%,%,$($(curdir)/subdirs)))
$(curdir)/subdirs := $(filter-out $(curdir),$($(curdir)/subdirs))
$(curdir)/subdirs := $(sort $($(curdir)/subdirs))

$(curdir)/subtargets:=dep unpack configure patch compile build install clean mostlyclean stampclean

STAMP_TOOLS_INSTALLED:=$(BUILD_DIR_HOST)/.installed

tools/install: $(STAMP_TOOLS_INSTALLED)
$(STAMP_TOOLS_INSTALLED):
	$(MAKE) -C tools/quilt install
	@for dir in $(tools/subdirs) ; do \
        $(MAKE) -C $$dir install || exit "$$?"; \
    done
	@touch $@

tools/clean:
	rm -rf $(BUILD_DIR_HOST)

define Build/tools
$(1)/$(2):
	+$$(MAKE) -C $(1) $(2)
endef

$(foreach dir,$(tools/subdirs), \
  $(foreach target,$(tools/subtargets), \
    $(eval $(call Build/tools,$(dir),$(target))) \
  ) \
)

