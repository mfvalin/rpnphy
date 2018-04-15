ifneq (,$(DEBUGMAKE))
$(info ## ====================================================================)
$(info ## File: $$rpnphy/include/Makefile.ssm.mk)
$(info ## )
endif
#---- SSM build  upport  -------------------------------------------

RPNPHY_SSMALL_NAME  = rpnphy$(RPNPHY_SFX)_$(RPNPHY_VERSION)_all
RPNPHY_SSMARCH_NAME = rpnphy$(RPNPHY_SFX)+$(COMP_ARCH)_$(RPNPHY_VERSION)_$(SSMARCH)
RPNPHY_SSMALL_FILES  = $(RPNPHY_SSMALL_NAME).ssm
RPNPHY_SSMARCH_FILES = $(RPNPHY_SSMARCH_NAME).ssm

SSM_DEPOT_DIR := $(HOME)/SsmDepot
SSM_BASE      := $(HOME)/SsmBundles
SSM_BASE2     := $(HOME)/SsmBundles
RPNPHY_SSM_BASE_DOM  = $(SSM_BASE)/ENV/d/$(RPNPHY_VERSION_X)rpnphy
RPNPHY_SSM_BASE_BNDL = $(SSM_BASE)/ENV/$(RPNPHY_VERSION_X)rpnphy
RPNPHY_INSTALL   = rpnphy_install
RPNPHY_UNINSTALL = rpnphy_uninstall

.PHONY: rpnphy_ssm rpnphy_ssm_all.ssm rm_rpnphy_ssm_all.ssm rpnphy_ssm_all rm_rpnphy_ssm_all rpnphy_ssm_arch.ssm rm_rpnphy_ssm_arch.ssm rpnphy_ssm_arch rpnphy_ssm_arch_rm
rpnphy_ssm: rpnphy_ssm_all.ssm rpnphy_ssm_arch.ssm
rm_rpnphy_ssm: rm_rpnphy_ssm_all.ssm rm_rpnphy_ssm_all rm_rpnphy_ssm_arch.ssm rpnphy_ssm_arch_rm

rpnphy_ssm_all.ssm: $(RPNPHY_SSMALL_FILES)
$(RPNPHY_SSMALL_FILES): rpnphy_ssm_all rm_rpnphy_ssm_all.ssm $(SSM_DEPOT_DIR)/$(RPNPHY_SSMALL_NAME).ssm
rm_rpnphy_ssm_all.ssm:
	rm -f $(SSM_DEPOT_DIR)/$(RPNPHY_SSMALL_NAME).ssm
$(SSM_DEPOT_DIR)/$(RPNPHY_SSMALL_NAME).ssm:
	cd $(BUILDSSM)  ;\
	chmod a+x $(basename $(notdir $@))/bin/* 2>/dev/null || true ;\
	tar czvf $@ $(basename $(notdir $@))
	ls -l $@

rpnphy_ssm_all: rm_rpnphy_ssm_all $(BUILDSSM)/$(RPNPHY_SSMALL_NAME)
rm_rpnphy_ssm_all:
	rm -rf $(BUILDSSM)/$(RPNPHY_SSMALL_NAME)
$(BUILDSSM)/$(RPNPHY_SSMALL_NAME):
	rm -rf $@ ; mkdir -p $@ ; \
	rsync -av --exclude-from=$(DIRORIG_rpnphy)/.ssm.d/exclude $(DIRORIG_rpnphy)/ $@/ ; \
	echo "Dependencies (s.ssmuse.dot): " > $@/BUILDINFO ; \
	cat $@/ssmusedep.bndl >> $@/BUILDINFO ; \
	.rdemk_ssm_control rpnphy $(RPNPHY_VERSION) all $@/BUILDINFO $@/DESCRIPTION > $@/.ssm.d/control

rpnphy_ssm_arch.ssm: $(RPNPHY_SSMARCH_FILES)
$(RPNPHY_SSMARCH_FILES): rpnphy_ssm_arch rm_rpnphy_ssm_arch.ssm $(SSM_DEPOT_DIR)/$(RPNPHY_SSMARCH_NAME).ssm
rm_rpnphy_ssm_arch.ssm:
	rm -f $(SSM_DEPOT_DIR)/$(RPNPHY_SSMARCH_NAME).ssm
$(SSM_DEPOT_DIR)/$(RPNPHY_SSMARCH_NAME).ssm:
	cd $(BUILDSSM) ; tar czvf $@ $(basename $(notdir $@))
	ls -l $@

rpnphy_ssm_arch: rpnphy_ssm_arch_rm $(BUILDSSM)/$(RPNPHY_SSMARCH_NAME)
rpnphy_ssm_arch_rm:
	rm -rf $(BUILDSSM)/$(RPNPHY_SSMARCH_NAME)
$(BUILDSSM)/$(RPNPHY_SSMARCH_NAME):
	mkdir -p $@/lib/$(EC_ARCH) ; \
	touch $@/lib/libdummy_$(RPNPHY_SSMARCH_NAME).a ; \
	cd $(LIBDIR) ; \
	rsync -av `ls librpnphy*.a librpnphy*.a.fl librpnphy*.so 2>/dev/null` $@/lib/$(EC_ARCH)/ ; \
	if [[ x$(MAKE_SSM_NOMOD) != x1 ]] ; then \
		mkdir -p $@/include/$(EC_ARCH) ; \
		touch $@/include/dummy_$(RPNPHY_SSMARCH_NAME).inc ; \
		cd $(MODDIR) ; \
		cp $(RPNPHY_MOD_FILES) $@/include/$(EC_ARCH) ; \
	fi ; \
	if [[ x$(MAKE_SSM_NOINC) != x1 ]] ; then \
		mkdir -p $@/include/$(EC_ARCH) ; \
		touch $@/include/dummy_$(RPNPHY_SSMARCH_NAME).mod ; \
		echo $(BASE_ARCH) > $@/include/$(BASE_ARCH)/.restricted ; \
		echo $(ORDENV_PLAT) >> $@/include/$(BASE_ARCH)/.restricted ; \
		echo $(EC_ARCH) > $@/include/$(EC_ARCH)/.restricted ; \
		echo $(ORDENV_PLAT)/$(COMP_ARCH) >> $@/include/$(EC_ARCH)/.restricted ; \
		.rdemkversionfile rpnphy $(RPNPHY_VERSION) $@/include/$(EC_ARCH) f ; \
		.rdemkversionfile rpnphy $(RPNPHY_VERSION) $@/include/$(EC_ARCH) c ; \
		.rdemkversionfile rpnphy $(RPNPHY_VERSION) $@/include/$(EC_ARCH) sh ; \
	fi ; \
	if [[ x$(MAKE_SSM_NOABS) != x1 ]] ; then \
		mkdir -p $@/bin/$(BASE_ARCH) ; \
		touch $@/bin/dummy_$(RPNPHY_SSMARCH_NAME).bin ; \
		cd $(BINDIR) ; \
		cp $(RPNPHY_ABS_FILES) $@/bin/$(BASE_ARCH) ; \
	fi ; \
	cp -R $(DIRORIG_rpnphy)/.ssm.d $@/ ; \
	.rdemk_ssm_control rpnphy $(RPNPHY_VERSION) $(SSMORDARCH) $@/BUILDINFO $@/DESCRIPTION > $@/.ssm.d/control 


.PHONY: rpnphy_install rpnphy_uninstall
rpnphy_install: 
	if [[ x$(CONFIRM_INSTALL) != xyes ]] ; then \
		echo "Please use: make $@ CONFIRM_INSTALL=yes" ;\
		exit 1;\
	fi
	cd $(SSM_DEPOT_DIR) ;\
	rdessm-install -v \
			--dest=$(RPNPHY_SSM_BASE_DOM)/rpnphy_$(RPNPHY_VERSION) \
			--bndl=$(RPNPHY_SSM_BASE_BNDL)/$(RPNPHY_VERSION).bndl \
			--pre=$(rpnphy)/ssmusedep.bndl \
			--post=$(rpnphy)/ssmusedep_post.bndl \
			--base=$(SSM_BASE2) \
			rpnphy{_,+*_,-d+*_}$(RPNPHY_VERSION)_*.ssm

rpnphy_uninstall:
	if [[ x$(UNINSTALL_CONFIRM) != xyes ]] ; then \
		echo "Please use: make $@ UNINSTALL_CONFIRM=yes" ;\
		exit 1;\
	fi
	cd $(SSM_DEPOT_DIR) ;\
	rdessm-install -v \
			--dest=$(RPNPHY_SSM_BASE_DOM)/rpnphy_$(RPNPHY_VERSION) \
			--bndl=$(RPNPHY_SSM_BASE_BNDL)/$(RPNPHY_VERSION).bndl \
			--base=$(SSM_BASE2) \
			--uninstall

ifneq (,$(DEBUGMAKE))
$(info ## ==== $$rpnphy/include/Makefile.ssm.mk [END] ========================)
endif
