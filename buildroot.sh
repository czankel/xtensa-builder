#!/bin/bash

# Build cross toolchain (part of buildroot)

# BUILDER_COMPONENT                 - 'buildroot-cross'
# BUILDER_BUILDROOT_NAME	    - Type of build (stable, origin, etc.)
# BUILDER_BUILDROOT_CONFIGS         - List of Xtensa configurations
# BUILDER_BUILDROOT_CONFIGS_DIR	    - Config file directory, or default if empty
# BUILDER_BUILDROOT_BUILTIN_CONFIGS - Configurations that come with buildroot
# BUILDER_BUILDROOT_HOST_DIR        - Host dir or empty for default

# BUILDER_COMPONENT
#  Describes the component the builder is requested to build,
#  so is always 'buildroot-cross' for this script.
#
# BUILDER_BUILDROOT_NAME
#  Descriptive name for this build and directory name
#
# BUILDER_BUILDROOT_CONFIGS
#  List of configurations postfixed by _defconfig.
#
# BUILDER_BUILDROOT_CONFIGS_DIR
#  Subdirectory that contains a set of configurations that should be used
#  for these builds.
#
# BUILDER_BUILDROOT_BUILTIN_CONFIGS
#  List of configurations that are included in buildroot and don't need to
#  be copied from the BUILDER_BUILDROOT_CONFIGS_DIR directory

echo -----------------------------------------------------------------
echo "BUILDER_BUILDROOT_*"
echo "  NAME:              ${BUILDER_BUILDROOT_NAME}"
echo "  CONFIGS:           ${BUILDER_BUILDROOT_CONFIGS}"
echo "  CONFIGS_DIR:       ${BUILDER_BUILDROOT_CONFIGS_DIR}"
echo "  BUILTIN_CONFIGS:   ${BUILDER_BUILDROOT_BUILTIN_CONFIGS}"
echo "  HOST_DIR:          ${BUILDER_BUILDROOT_HOST_DIR}"

rm -fr buildroot/output-*
rm  buildroot/dl
ln -s /share/cache/buildroot/dl buildroot/dl

OVERLAY_DIR=builder/buildroot/overlay
CONFIGS_DIR=builder/buildroot/configs/${BUILDER_BUILDROOT_CONFIGS_DIR}
BUILDROOT_DIR=buildroot

for CONFIG in ${BUILDER_BUILDROOT_CONFIGS}
do

	# host and output directory for the build
	OUTPUT_DIR=output-${CONFIG}
	mkdir buildroot/${OUTPUT_DIR}

	# make 'DEFCONFIG_RULE' uses 'DEFCONFIG_NAME' for built-in configs
	DEFCONFIG_NAME=${CONFIG}_defconfig
	DEFCONFIG_FILE=buildroot/configs/${DEFCONFIG_NAME}
	DEFCONFIG_RULE=${DEFCONFIG_NAME}

	if [[ ! "$BUILDER_BUILDROOT_BUILTIN_CONFIGS" =~ "${CONFIG}" ]]; then
		DEFCONFIG_FILE=${CONFIGS_DIR}/${DEFCONFIG_NAME}
		DEFCONFIG_RULE=defconfig
		cp ${DEFCONFIG_FILE} buildroot/${OUTPUT_DIR}/.defconfig
	fi

	# determine processor variant
	eval `grep "BR2_XTENSA_CORE_NAME" ${DEFCONFIG_FILE}`
	VARIANT=${BR2_XTENSA_CORE_NAME}
	if [ -z "${VARIANT}" ]; then
		VARIANT=`grep "BR2_xtensa_.*=y" ${DEFCONFIG_FILE} | \
			 sed 's/BR2_xtensa_\(.*\)=y/\`/'`
		VARIANT=${VARIANT,,}
	fi

	# determine HOST DIR
	HOST_DIR="<default>"
	if [ -n "${BUILDER_BUILDROOT_HOST_DIR}" ]; then
		HOST_DIR="${BUILDER_BUILDROOT_HOST_DIR}/${VARIANT}" 
		sed 's/BR2_HOST_DIR.*/BR2_HOST_DIR="${HOST_DIR}"/' \
		${OUTPUT_DIR}/.config
	fi

	echo -----------------------------------------------------------------
	echo "OUTPUT_DIR:          ${OUTPUT_DIR}"
	echo "HOST_DIR:            ${HOST_DIR}"
	echo "VARIANT:             ${VARIANT}"
	echo "DEFCONFIG_RULE:      ${DEFCONFIG_RULE}"
	echo "DEFCONFIG_NAME:      ${DEFCONFIG_NAME}"
	echo "DEFCONFIG_FILE:      ${DEFCONFIG_FILE}"
	echo

	(cd buildroot && make V=1 O=${OUTPUT_DIR} ${DEFCONFIG_RULE})
	if [ $? -ne 0 ]; then echo ERROR.; exit 1 ; fi

	(cd buildroot && make V=1 O=${OUTPUT_DIR})
	if [ $? -ne 0 ]; then echo ERROR.; exit 1 ; fi

	(cd buildroot && rm -f ${OUTPUT_DIR}/.config && make clean)
done
