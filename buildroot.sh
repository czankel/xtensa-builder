#!/bin/bash

# BUILDER_COMPONENT		- 'buildroot'
# BUILDER_VARIANTS		- Xtensa processor variant
# BUILDER_BUILTIN_VARIANTS	- Variants to use defconfig from builtroot
# BUILDER_OVERLAY_DIR		- Containing all overlay files
# BUILDER_CONFIG_DIR		- Non-built-in configuration files
# BUILDER_BUILDROOT_ORIGIN	- Repository
# BUILDER_BUILDROOT_CONFIG	- Non-built-in configuration type (stable, all, latest)

echo BUILDER_COMPONENT:   ${BUILDER_COMPONENT}
echo BUILDER_VARIANTS:    ${BUILDER_VARIANTS}

rm -fr buildroot/output* buildroot/dl
ln -s /share/cache/buildroot/dl buildroot/dl

for VARIANT in ${BUILDER_VARIANTS}
do
	# make 'DEFCONFIG_RULE' uses 'DEFCONFIG_NAME' for built-in configurations
	DEFCONFIG_NAME=xtensa_${VARIANT}_defconfig
	DEFCONFIG_RULE=${DEFCONFIG_NAME}

	# output directory for the build
	OUTPUT_DIR=xtensa_${VARIANT}-${BUILDER_BUILDROOT_ORIGIN}-${BUILDER_BUILDROOT_CONFIG}
	
	
	if [[ ! "$BUILDER_BUILTIN_VARIANTS" =~ "$VARIANT" ]]; then
		DEFCONFIG_FILE=${BUILDER_CONFIG_DIR}/${BUILDER_BUILDROOT_RELEASE}/${DEFCONFIG_NAME}
		DEFCONFIG_RULE=defconfig
		cp ${DEFCONFIG_FILE} buildroot/${OUTPUT_DIR}/.defconfig
		# FIXME: patch VARIANT
	fi

	echo BUILDER_COMPONENT:   ${BUILDER_COMPONENT}
	echo VARIANT:     	  ${VARIANT}
	echo BUILDER_CONFIG_DIR:  ${BUILDER_CONFIG_DIR}
	echo BUILDER_CONFIG_NAME: ${BUILDER_CONFIG_NAME}
	echo
	echo DEFCONFIG_RULE:      ${DEFCONFIG_RULE}
	echo DEFCONFIG_NAME:      ${DEFCONFIG_NAME}
	echo DEFCONFIG_FILE:      ${DEFCONFIG_FILE}
	echo
	echo OUTPUT_DIR:          ${OUTPUT_DIR}

	(cd buildroot && make V=1 O=${OUTPUT_DIR} ${DEFCONFIG_RULE} && make V=1 O=${OUTPUT_DIR} )

done
