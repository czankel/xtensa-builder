#!/bin/bash

# Build kernel

# BUILDER_KERNEL_NAME               - Type or name of build
# BUILDER_KERNEL_TARGET             - <platform>,<variant>
# BUILDER_KERNEL_CONFIGS_DIR        - Directory with additional configurations
# BUILDER_KERNEL_BUILTIN_CONFIGS    - Configurations that come with the kernel
# BUILDER_KERNEL_BUILDROOT_HOST_DIR - Buildroot ${HOSTDIR}

echo -----------------------------------------------------------------
echo "NAME:                ${BUILDER_KERNEL_NAME}"
echo "TARGET:              ${BUILDER_KERNEL_TARGET}"
echo "CONFIGS_DIR          ${BUILDER_KERNEL_CONFIGS_DIR}"
echo "BUILTIN_CONFIGS:     ${BUILDER_KERNEL_BUILTIN_CONFIGS}"
echo "BUILDROOT_HOST_DIR:  ${BUILDER_KERNEL_BUILDROOT_HOST_DIR}"
echo "BUILDER_WORKSPACE:   ${BUILDER_WORKSPACE}"


CONFIG_DIR=builder/kernel/configs/${BUILDER_KERNEL_CONFIGS_DIR}

TARGETARR=(${BUILDER_KERNEL_TARGET//,/ })
PLATFORM=${TARGETARR[0]}
VARIANT=${TARGETARR[1]}

DEFCONFIG=${PLATFORM}_defconfig
KERNELDIR=${BUILDER_WORKSPACE}/kernel
BUILDDIR=${WORKSPACE}/output-${PLATFORM}-${VARIANT}

rm -fr ${BUILDDIR}
mkdir -p ${BUILDDIR}

IS_BUILTIN_CONFIG=""
if [[ ! "${BUILDER_KERNEL_BUILTIN_CONFIGS}" =~ "${PLATFORM}" ]]; then
	echo COPY ${BUILDER_KERNEL_CONFIGS_DIR}/${DEFCONFIG} to ${BUILDDIR}/.config
	cp ${BUILDER_KERNEL_CONFIGS_DIR}/${DEFCONFIG} \
	   ${BUILDDIR}/.config
	if [ $? -ne 0 ]; then
		echo ERROR.
		exit 1
	fi
else
	echo COPY ${KERNELDIR}/arch/xtensa/configs/${DEFCONFIG} ${BUILDDIR}/.config
	cp ${KERNELDIR}/arch/xtensa/configs/${DEFCONFIG} ${BUILDDIR}/.config
	if [ $? -ne 0 ]; then
		echo ERROR.
		exit 1
	fi
	IS_BUILTIN_CONFIG="[builtin]"
fi

CONFIG_VARIANT=`grep CONFIG_XTENSA_VARIANT_${VARIANT^^} ${BUILDDIR}/.config`

# delete all CONFIG_XTENSA_VARIANT entries (including MMU for CUSTOM variant)
sed -e "/.*CONFIG_XTENSA_VARIANT.*/d" -i ${BUILDDIR}/.config

IS_BUILTIN_VARIANT=""
if [[ -z ${CONFIG_VARIANT} ]]; then
	# might not need the first entry anymore?
	echo "CONFIG_XTENSA_VARIANT_CUSTOM=y" >> ${BUILDDIR}/.config
	echo "CONFIG_XTENSA_VARIANT_CUSTOM_NAME=\"${VARIANT}\"" >> ${BUILDDIR}/.config
	echo "CONFIG_XTENSA_VARIANT_MMU=y" >> ${BUILDDIR}/.config
else
	# might not need this entry anymore?
	echo "CONFIG_XTENSA_VARIANT_${VARIANT^^}=y" >> ${BUILDDIR}/.config
	IS_BUILTIN_VARIANT="[builtin]"
fi

echo "CONFIG_XTENSA_VARIANT_NAME=\"${VARIANT}\"" >> ${BUILDDIR}/.config


HOSTDIR="${BUILDER_KERNEL_BUILDROOT_HOST_DIR}/${VARIANT}"

echo -----------------------------------------------------------------
echo "DEFCONFIG:           ${DEFCONFIG} ${IS_BUILTIN_CONFIG}"
echo "PLATFORM:            ${PLATFORM}"
echo "VARIANT:             ${VARIANT} ${IS_BUILTIN_VARIANT}"
echo "KERNELDIR:           ${KERNELDIR}"
echo "BUILDDIR:            ${BUILDDIR}"
echo "HOSTDIR:             ${HOSTDIR}"


export PATH=${HOSTDIR}/usr/bin:$PATH

(cd ${KERNELDIR} \
 && make ARCH=xtensa CROSS_COMPILE=xtensa-linux- O=${BUILDDIR} oldconfig \
 && make ARCH=xtensa CROSS_COMPILE=xtensa-linux- O=${BUILDDIR})

if [ $? -ne 0 ]; then
	echo ERROR
	exit 1
fi

export PATH=$(printf "%s" "$PATH" | sed 's/[\:]*//')

echo OK.
