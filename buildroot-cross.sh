#!/bin/bash

# Build cross toolchain (part of buildroot)

# BUILDER_COMPONENT                 - 'buildroot-cross'
# BUILDER_BUILDROOT_NAME	    - Type of build (stable, origin, etc.)
# BUILDER_BUILDROOT_TARGETS         - List of Xtensa processor variants to build
# BUILDER_BUILDROOT_CONFIGS_DIR	    - Config file directory, or default if empty
# BUILDER_BUILDROOT_BUILTIN_CONFIGS - Configurations that come with buildroot
# BUILDER_BUILDROOT_HOST_DIR

# BUILDER_COMPONENT
#  Describes the component the builder is requested to build,
#  so is always 'buildroot-cross' for this script.
#
# BUILDER_BUILDROOT_NAME
#  Descriptive name for this build and directory name
#
# BUILDER_BUILDROOT_TARGETS
#  List of of board and Xtensa porcessor variant in the format 'variant,board'.
#  The variant and board describes whatthat should be build. For example, 'fsf,fsf', 'lx60,dc232b'.
#  Note that the 'fsf' board target is a special target.
#  The build script builds all specified variants sequentially.
#  The variant name is used for the following variables:
#  - overlay file: <variant>_defconfig
#
# BUILDER_BUILDROOT_CONFIGS_DIR
#  Subdirectory that contains a set of configurations that should be used
#  for these builds.
#
# BUILDER_BUILDROOT_BUILTIN_CONFIGS
#  List of configurations that are included in buildroot and don't need to
#  be copied from the BUILDER_BUILDROOT_CONFIGS_DIR directory

echo -----------------------------------------------------------------
echo "NAME:                ${BUILDER_BUILDROOT_NAME}"
echo "TARGETS:             ${BUILDER_BUILDROOT_TARGETS}"
echo "CONFIGS_DIR:         ${BUILDER_BUILDROOT_CONFIGS_DIR}"
echo "BUILTIN_CONFIGS:     ${BUILDER_BUILDROOT_BUILTIN_CONFIGS}"

rm -fr buildroot/output-* buildroot/dl
ln -s /share/cache/buildroot/dl buildroot/dl

OVERLAY_DIR=builder/buildroot/overlay
CONFIG_DIR=builder/buildroot/configs/${BUILDER_BUILDROOT_CONFIGS_DIR}
OVERLAY_BUILTIN_VARIANTS=fsf

for TARGET in ${BUILDER_BUILDROOT_TARGETS}
do
	BOARD=${TARGET%,*}
	VARIANT=${TARGET#*,}

	# make 'DEFCONFIG_RULE' uses 'DEFCONFIG_NAME' for built-in configs
	DEFCONFIG_FILE=
	DEFCONFIG_NAME=${BOARD}_${VARIANT}_defconfig
	DEFCONFIG_RULE=${DEFCONFIG_NAME}

	# output directory for the build
	OUTPUT_DIR=output-${BOARD}-${VARIANT}
	mkdir buildroot/${OUTPUT_DIR}

	if [[ ! "$BUILDER_BUILDROOT_BUILTIN_CONFIGS" =~ "${TARGET}" ]]; then
		DEFCONFIG_FILE=${CONFIG_DIR}/${DEFCONFIG_NAME}
		DEFCONFIG_RULE="BR2_DEFCONFIG=`pwd`/${DEFCONFIG_FILE} defconfig"
	fi
	HOST_DIR=${BUILDER_BUILDROOT_HOST_DIR}/${VARIANT}
	
	echo -----------------------------------------------------------------
	echo "BOARD:               ${BOARD}"
	echo "VARIANT:             ${VARIANT}"
	echo
	echo "DEFCONFIG_RULE:      ${DEFCONFIG_RULE}"
	echo "DEFCONFIG_NAME:      ${DEFCONFIG_NAME}"
	echo "DEFCONFIG_FILE:      ${DEFCONFIG_FILE}"
	echo
	echo "OUTPUT_DIR:          ${OUTPUT_DIR}"
	echo "HOST_DIR:            ${HOST_DIR}"
	echo

	(cd buildroot && make V=1 O=${OUTPUT_DIR} ${DEFCONFIG_RULE})
	if [ $? -ne 0 ]; then
		exit 1
	fi

	# update hostdir
	CONFIG_FILE="buildroot/${OUTPUT_DIR}/.config"
	TMP=$(printf "%s\n" "$HOST_DIR" | sed 's/[][\.*^$(){}?+|/]/\\&/g')
	sed -e "s/BR2_HOST_DIR.*/BR2_HOST_DIR=\"${TMP}\"/" -i ${CONFIG_FILE}
	if [ $? -ne 0 ]; then
		exit 1
	fi

	(cd buildroot && make V=1 O=${OUTPUT_DIR})
	if [ $? -ne 0 ]; then
		exit 1
	fi

	# delete .config, so make clean won't delete the HOST_DIR
	(cd buildroot && rm -f ${OUTPUT_DIR}/.config && make clean)
done
