ifneq ($(__quilt_inc),1)
__quilt_inc=1

PATCH_DIR?=./patches
FILES_DIR?=./files

QUILT_CMD:=quilt --quiltrc=-

define filter_series
sed -e s,\\\#.*,, $(1) | grep -E \[a-zA-Z0-9\]
endef

define PatchDir/Quilt
	@mkdir -p "$(1)/patches$(if $(3),/$(patsubst %/,%,$(3)))"
	@if [ -s "$(2)/series" ]; then \
		mkdir -p "$(1)/patches/$(3)"; \
		cp "$(2)/series" "$(1)/patches/$(3)"; \
	fi
	@for patch in $$$$( (cd "$(2)" && if [ -f series ]; then $(call filter_series,series); else ls | sort; fi; ) 2>/dev/null ); do ( \
		cp "$(2)/$$$$patch" "$(1)/patches/$(3)"; \
		echo "$(3)$$$$patch" >> "$(1)/patches/series"; \
	); done
	$(if $(3),@echo $(3) >> "$(1)/patches/.subdirs")
endef

define Build/Patch/Default
	@rm -rf $(1)/patches; mkdir -p $(1)/patches
	@if [ -d $(FILES_DIR) ]; then \
		$(CP) $(FILES_DIR)/* $(1)/; \
	fi
	$(call PatchDir/Quilt,$(1),$(PATCH_DIR),)
	if [ -s "$(1)/patches/series" ]; then \
		(cd "$(1)"; \
			if quilt next >/dev/null 2>&1; then \
				quilt push -a; \
			else \
				quilt top >/dev/null 2>&1; \
			fi \
		); \
	fi	
endef

kernel_files=$(foreach fdir,$(GENERIC_FILES_DIR) $(FILES_DIR),$(fdir)/.)
define Kernel/Patch/Default
	@rm -rf $(PKG_BUILD_DIR)/patches; mkdir -p $(PKG_BUILD_DIR)/patches
	$(if $(kernel_files),$(CP) $(kernel_files) $(PKG_BUILD_DIR)/)
	$(call PatchDir/Quilt,$(PKG_BUILD_DIR),$(GENERIC_PATCH_DIR),generic/)
	$(call PatchDir/Quilt,$(PKG_BUILD_DIR),$(PATCH_DIR),platform/)
	if [ -s "$(PKG_BUILD_DIR)/patches/series" ]; then \
		(cd "$(PKG_BUILD_DIR)"; \
			if $(QUILT_CMD) next >/dev/null 2>&1; then \
				$(QUILT_CMD) push -a; \
			else \
				$(QUILT_CMD) top >/dev/null 2>&1; \
			fi \
		); \
	fi
endef

endif #__quilt_inc