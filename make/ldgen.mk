# Makefile to support the linker script generation mechanism

LDGEN_SECTIONS_INFO_FILES = $(foreach lib, $(COMPONENT_LIBRARIES), $(BUILD_DIR_BASE)/$(lib)/lib$(lib).a.sections_info)
LDGEN_FRAGMENT_FILES = $(COMPONENT_LDFRAGMENTS)

# Target to generate linker script generator from fragments presented by each of
# the components
define ldgen_process_template
$(BUILD_DIR_BASE)/ldgen.section_infos: $(LDGEN_SECTIONS_INFO_FILES) $(IDF_PATH)/make/ldgen.mk
	printf "$(foreach section_info,$(LDGEN_SECTIONS_INFO_FILES),$(section_info)\n)" > $(BUILD_DIR_BASE)/ldgen.section_infos
	sed -E -i.bak 's|^[[:blank:]]*||g' $(BUILD_DIR_BASE)/ldgen.section_infos
	rm $(BUILD_DIR_BASE)/ldgen.section_infos.bak
ifeq ($(OS), Windows_NT)
	mv $(BUILD_DIR_BASE)/ldgen.section_infos $(BUILD_DIR_BASE)/ldgen.section_infos.temp
	cygpath -w -f $(BUILD_DIR_BASE)/ldgen.section_infos.temp > $(BUILD_DIR_BASE)/ldgen.section_infos
	rm -f $(BUILD_DIR_BASE)/ldgen.section_infos.temp
endif

$(2): $(1) $(LDGEN_FRAGMENT_FILES) $(SDKCONFIG) $(BUILD_DIR_BASE)/ldgen.section_infos
	@echo 'Generating $(notdir $(2))'
	$(PYTHON) $(IDF_PATH)/tools/ldgen/ldgen.py \
		--input         $(1) \
		--config        $(SDKCONFIG) \
		--fragments     $(LDGEN_FRAGMENT_FILES) \
		--output        $(2) \
		--sections      $(BUILD_DIR_BASE)/ldgen.section_infos \
		--kconfig       $(IDF_PATH)/Kconfig \
		--env           "COMPONENT_KCONFIGS=$(COMPONENT_KCONFIGS)" \
		--env           "COMPONENT_KCONFIGS_PROJBUILD=$(COMPONENT_KCONFIGS_PROJBUILD)" \
		--env           "IDF_CMAKE=n"
endef

define ldgen_create_commands
$(foreach lib, $(COMPONENT_LIBRARIES), \
	$(eval $(call ldgen_generate_target_sections_info, $(BUILD_DIR_BASE)/$(lib)/lib$(lib).a)))

ldgen-clean:
	rm -f $(LDGEN_SECTIONS_INFO_FILES)
	rm -f $(BUILD_DIR_BASE)/ldgen.section_infos
endef

# Target to generate sections info file from objdump of component archive
define ldgen_generate_target_sections_info
$(1).sections_info: $(1)
	@echo 'Generating $(notdir $(1).sections_info)'
	$(OBJDUMP) -h $(1) > $(1).sections_info
endef
