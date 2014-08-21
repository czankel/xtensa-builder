#!/bin/bash

# Build kernel

# BUILDER_COMPONENT                 - 'kernel'
# BUILDER_KERNEL_NAME               - Type or name of build
# BUILDER_KERNEL_CONFIGS            - List of board and processor variants to build
# BUILDER_KERNEL_CONFIGS_DIR        - Additional configurations
# BUILDER_KERNEL_BUILTIN_CONFIGS    - Configurations that come with the kernel
# BUILDER_KERNEL_BUILDROOT_HOST_DIR - Buildroot ${HOSTDIR}

echo -----------------------------------------------------------------
echo "NAME:                ${BUILDER_KERNEL_NAME}"
echo "CONFIGS:             ${BUILDER_KERNEL_CONFIGS}"
echo "CONFIGS_DIR          ${BUILDER_KERNEL_CONFIGS_DIR}"
echo "BUILTIN_CONFIGS:     ${BUILDER_KERNEL_BUILTIN_CONFIGS}"
echo "BUILDROOT_HOST_DIR:  ${BUILDER_KERNEL_BUILDROOT_HOST_DIR}"

rm -fr kernel/output-*

CONFIG_DIR=builder/kernel/configs/${BUILDER_KERNEL_CONFIGS_DIR}

for CONFIG in ${BUILDER_KERNEL_CONFIGS}
do
	DEFCONFIG=${CONFIG}_defconfig
	OUTPUT_DIR=output-${CONFIG}

	mkdir -p kernel/${OUTPUT_DIR}

	IS_BUILTIN=""
	if [[ ! "${BUILDER_KERNEL_BUILTIN_CONFIGS}" =~ "${CONFIG}" ]]; then
		cp ${BUILDER_KERNEL_CONFIGS_DIR}/${DEFCONFIG} kernel/${OUTPUT_DIR}/.config
		if [ $? -ne 0 ]; then
			echo ERROR.
			exit 1
		fi
	else
		cp kernel/arch/xtensa/configs/${DEFCONFIG} kernel/${OUTPUT_DIR}/.config
		if [ $? -ne 0 ]; then
			echo ERROR.
			exit 1
		fi
		IS_BUILTIN="[builtin]"
	fi

	VARIANT=`grep "CONFIG_XTENSA_VARIANT.*=y" kernel/${OUTPUT_DIR}/.config | \
		 sed 's/CONFIG_XTENSA_VARIANT_\(.*\)=y/\1/'`
	VARIANT=${VARIANT,,}
        HOST_DIR=${BUILDER_KERNEL_BUILDROOT_HOST_DIR}/${VARIANT}

	echo -----------------------------------------------------------------
        echo "DEFCONFIG:           ${DEFCONFIG} ${IS_BUILTIN}"
	echo "VARIANT:             ${VARIANT}"
        echo "OUTPUT_DIR:          ${OUTPUT_DIR}"
        echo "HOST_DIR:            ${HOST_DIR}"


	export PATH=${HOST_DIR}/usr/bin:$PATH

	(cd kernel \
	 && make ARCH=xtensa CROSS_COMPILE=xtensa-linux- O=${OUTPUT_DIR} oldconfig \
	 && make ARCH=xtensa CROSS_COMPILE=xtensa-linux- O=${OUTPUT_DIR})

	if [ $? -ne 0 ]; then
		echo ERROR
		exit 1
	fi

	export PATH=$(printf "%s" "$PATH" | sed 's/[\:]*//')

done

echo OK.
