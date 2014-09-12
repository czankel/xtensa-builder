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

IS_BUILTIN=""
if [[ ! "${BUILDER_KERNEL_BUILTIN_CONFIGS}" =~ "${PLATFORM}" ]]; then
	cp ${BUILDER_KERNEL_CONFIGS_DIR}/${DEFCONFIG} \
	   ${BUILDDIR}/.config
	if [ $? -ne 0 ]; then
		echo ERROR.
		exit 1
	fi
else
	cp ${KERNELDIR}/${DEFCONFIG} ${BUILDDIR}/.config
	if [ $? -ne 0 ]; then
		echo ERROR.
		exit 1
	fi
	IS_BUILTIN="[builtin]"
fi

HOSTDIR="${BUILDER_KERNEL_BUILDROOT_HOST_DIR}/${VARIANT}"

echo -----------------------------------------------------------------
echo "DEFCONFIG:           ${DEFCONFIG} ${IS_BUILTIN}"
echo "PLATFORM:            ${PLATFORM}"
echo "VARIANT:             ${VARIANT}"
echo "KERNELDIR:           ${KERNELDIR}"
echo "BUILDDIR:            ${BUILDDIR}"
echo "HOSTDIR:             ${HOSTDIR}"


export PATH=${HOSTDIR}/usr/bin:$PATH

(cd ${KERNELDIR} \
 && make ARCH=xtensa CROSS_COMPILE=xtensa-linux- O=${BUILDDIR} oldconfig \
 && make ARCH=xtensa CROSS_COMPILE=xtensa-linux- O=${BUIDLDIR})

if [ $? -ne 0 ]; then
	echo ERROR
	exit 1
fi

export PATH=$(printf "%s" "$PATH" | sed 's/[\:]*//')

echo OK.
