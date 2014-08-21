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
echo "  DIR:               ${BUILDER_BUILDROOT_DIR}"
echo "  DL_DIR:            ${BUILDER_BUILDROOT_DL_DIR}"   

if [ -z "${BUILDER_BUILDROOT_DIR}" ]; then
  echo "Buildroot directory must be specified!"
  exit 1;
fi

if [ -z "${BUILDER_BUILDROOT_DL_DIR}" ]; then
  echo "DL directory must be specified!"
  exit 1;
fi

rm -fr ${BUILDER_BUILDROOT_DIR}/output-*
rm -f ${BUILDER_BUILDROOT_DIR}/dl

mkdir -p ${BUILDER_BUILDROOT_DL_DIR}
mkdir -p ${BUILDER_BUILDROOT_DIR}
ln -s ${BUILDER_BUILDROOT_DL_DIR} ${BUILDER_BUILDROOT_DIR}/dl

OVERLAY_DIR=`pwd`/builder/buildroot/overlay
CONFIGS_DIR=builder/buildroot/configs/${BUILDER_BUILDROOT_CONFIGS_DIR}
BUILDROOT_DIR=buildroot
OVERLAY_BUILTIN_VARIANTS=fsf

for CONFIG in ${BUILDER_BUILDROOT_CONFIGS}
do

	# host and output directory for the build
	OUTPUT_DIR=output-${CONFIG}
	mkdir ${BUILDER_BUILDROOT_DIR}/${OUTPUT_DIR}
	if [ $? -ne 0 ]; then
		echo "ERROR: Can't create ${BUILDER_BUILDROOT_DIR}/${OUTPUT_DIR}"
		exit 1
	fi

	# make 'DEFCONFIG_RULE' uses 'DEFCONFIG_NAME' for built-in configs
	DEFCONFIG_NAME=${CONFIG}_defconfig
	DEFCONFIG_FILE=${BUILDER_BUILDROOT_DIR}/configs/${DEFCONFIG_NAME}
	DEFCONFIG_RULE=${DEFCONFIG_NAME}

	if [[ ! "$BUILDER_BUILDROOT_BUILTIN_CONFIGS" =~ "${CONFIG}" ]]; then
		DEFCONFIG_FILE=${CONFIGS_DIR}/${DEFCONFIG_NAME}
		DEFCONFIG_RULE="BR2_DEFCONFIG=builder_defconfig defconfig"
		cp ${DEFCONFIG_FILE} \
			${BUILDER_BUILDROOT_DIR}/builder_defconfig
		if [ $? -ne 0 ]; then
			echo "ERROR: Config file ${DEFCONFIG_FILE} doesn't exist"
			exit 1
		fi
	fi 

	# determine processor variant
	eval `grep "BR2_XTENSA_CORE_NAME" ${DEFCONFIG_FILE}`
	VARIANT=${BR2_XTENSA_CORE_NAME}
	if [ -z "${VARIANT}" ]; then
		VARIANT=`grep "BR2_xtensa_.*=y" ${DEFCONFIG_FILE} | \
			 sed 's/BR2_xtensa_\(.*\)=y/\1/'`
		VARIANT=${VARIANT,,}
	fi

	# determine HOST DIR
	HOST_DIR="<default>"
	if [ -n "${BUILDER_BUILDROOT_HOST_DIR}" ]; then
		HOST_DIR="${BUILDER_BUILDROOT_HOST_DIR}/${VARIANT}" 
	fi

	echo -----------------------------------------------------------------
	echo "OUTPUT_DIR:          ${OUTPUT_DIR}"
	echo "HOST_DIR:            ${HOST_DIR}"
	echo "VARIANT:             ${VARIANT}"
	echo "DEFCONFIG_RULE:      ${DEFCONFIG_RULE}"
	echo "DEFCONFIG_NAME:      ${DEFCONFIG_NAME}"
	echo "DEFCONFIG_FILE:      ${DEFCONFIG_FILE}"
	echo

	(cd ${BUILDER_BUILDROOT_DIR} && \
	 make V=1 O=${OUTPUT_DIR} ${DEFCONFIG_RULE})

        # update overlaydir
        if [[ ! "$OVERLAY_BUILTIN_VARIANTS" =~ "${VARIANT}" ]]; then
                TMP=$(printf "%s\n" "$OVERLAY_DIR" | \
		      sed 's/[][\.*^$(){}?+|/]/\\&/g')
                sed -e "s/\(BR2_XTENSA_OVERLAY_DIR\).*/\1=\"${TMP}\"/" \
		    -i ${BUILDER_BUILDROOT_DIR}/${OUTPUT_DIR}/.config
        fi

	# update host dir
	if [ $? -ne 0 ]; then echo ERROR.; exit 1 ; fi

	if [ -n "${BUILDER_BUILDROOT_HOST_DIR}" ]; then
		rm -fr "${BUILDER_BUILDROOT_HOST_DIR}/${VARIANT}"
                TMP=$(printf "%s\n" "$HOST_DIR" | \
		      sed 's/[][\.*^$(){}?+|/]/\\&/g')
		sed -e "s/\(BR2_HOST_DIR\).*/\1=\"${TMP}\"/" \
		    -i ${BUILDER_BUILDROOT_DIR}/${OUTPUT_DIR}/.config
	fi

	(cd ${BUILDER_BUILDROOT_DIR} && make V=1 O=${OUTPUT_DIR})
	if [ $? -ne 0 ]; then echo ERROR.; exit 1 ; fi

	# remove .config so we don't delete the external host dir
	(cd ${BUILDER_BUILDROOT_DIR} && make clean)
done
