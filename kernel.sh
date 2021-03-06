#!/bin/bash

# Build kernel

# BUILDER_KERNEL_NAME               - Type or name of build
# BUILDER_KERNEL_TARGET             - <platform>.<variant>.<make-config>
# BUILDER_KERNEL_CONFIGS_DIR        - Directory with additional configurations
# BUILDER_KERNEL_BUILTIN_CONFIGS    - Configurations that come with the kernel
# BUILDER_KERNEL_BUILDROOT_HOST_DIR - Buildroot ${HOSTDIR}

echo -----------------------------------------------------------------
echo "NAME:                ${BUILDER_KERNEL_NAME}"
echo "TARGET:              ${BUILDER_KERNEL_TARGET}"
echo "MAKE_CONFIG:         ${BUILDER_KERNEL_MAKE_CONFIG}"
echo "CONFIGS_DIR          ${BUILDER_KERNEL_CONFIGS_DIR}"
echo "BUILTIN_CONFIGS:     ${BUILDER_KERNEL_BUILTIN_CONFIGS}"
echo "BUILDROOT_HOST_DIR:  ${BUILDER_KERNEL_BUILDROOT_HOST_DIR}"
echo "BUILDER_WORKSPACE:   ${BUILDER_WORKSPACE}"



TARGETARR=(${BUILDER_KERNEL_TARGET//./ })
PLATFORM=${TARGETARR[0]}
VARIANT=${TARGETARR[1]}

if [[ -z ${BUILDER_KERNEL_MAKE_CONFIG} ]]; then
	MAKE_CONFIG=${TARGETARR[2]}
else
	MAKE_CONFIG=${BUILDER_KERNEL_MAKE_CONFIG}
fi


DEFCONFIG=${PLATFORM}_defconfig
KERNELDIR=${BUILDER_WORKSPACE}/kernel
BUILDDIR=${WORKSPACE}/output-${PLATFORM}-${VARIANT}-${MAKE_CONFIG}
CONFIGDIR=${BUILDER_WORKSPACE}/builder/kernel/configs/${BUILDER_KERNEL_CONFIGS_DIR}

rm -fr ${BUILDDIR}
mkdir -p ${BUILDDIR}

IS_BUILTIN_CONFIG=""
if [[ ! "${BUILDER_KERNEL_BUILTIN_CONFIGS}" =~ "${PLATFORM}" ]]; then
	echo COPY ${CONFIGDIR}/${DEFCONFIG} to ${BUILDDIR}/.config
	cp ${CONFIGDIR}/${DEFCONFIG} ${BUILDDIR}/.config
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

sed -e "s/\(CONFIG_XTENSA_VARIANT_.*\)=y/# \1 is not set/" \
    -i ${BUILDDIR}/.config

IS_BUILTIN_VARIANT=""
if [[ -z ${CONFIG_VARIANT} ]]; then
	sed -e "s/# \(CONFIG_XTENSA_VARIANT_CUSTOM\).*/\1=y\nCONFIG_XTENSA_VARIANT_CUSTOM_NAME=\"${VARIANT}\"/" -i ${BUILDDIR}/.config
else
	sed -e "s/# \(CONFIG_XTENSA_VARIANT_${VARIANT^^}\).*/\1=y/" \
            -i ${BUILDDIR}/.config
	IS_BUILTIN_VARIANT="[builtin]"
fi

if [[ -z `grep CONFIG_XTENSA_VARIANT_NAME` ]]; then
	sed -e "s/\(.*CONFIG_XTENSA_UNALIGNED_USER.*\)/CONFIG_XTENSA_VARIANT_NAME=\"${VARIANT}\"\n\1/" \
	    -i ${BUILDDIR}/.config
else
	sed -e "s/CONFIG_XTENSA_VARIANT_NAME=.*/CONFIG_XTENSA_VARIANT_NAME=\"${VARIANT}\"/" -i ${BUILDDIR}/.config
fi


HOSTDIR="${BUILDER_KERNEL_BUILDROOT_HOST_DIR}/${VARIANT}"

echo -----------------------------------------------------------------
echo "DEFCONFIG:           ${DEFCONFIG} ${IS_BUILTIN_CONFIG}"
echo "MAKE_CONFIG:         ${MAKE_CONFIG}"
echo "PLATFORM:            ${PLATFORM}"
echo "VARIANT:             ${VARIANT} ${IS_BUILTIN_VARIANT}"
echo "KERNELDIR:           ${KERNELDIR}"
echo "BUILDDIR:            ${BUILDDIR}"
echo "HOSTDIR:             ${HOSTDIR}"


export PATH=${HOSTDIR}/usr/bin:$PATH

(cd ${KERNELDIR} \
 && make ARCH=xtensa CROSS_COMPILE=xtensa-linux- O=${BUILDDIR} ${MAKE_CONFIG} \
 && make ARCH=xtensa CROSS_COMPILE=xtensa-linux- O=${BUILDDIR})

if [ $? -ne 0 ]; then
	echo ERROR, build failed.
	exit 1
fi

export PATH=$(printf "%s" "$PATH" | sed 's/[\:]*//')

echo OK.
