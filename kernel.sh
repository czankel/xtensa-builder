#!/bin/bash

echo BUILDER_COMPONENT:   ${BUILDER_COMPONENT}
echo BUILDER_VARIANTS:    ${BUILDER_VARIANTS}

rm -fr kernel/output*

echo buildroot origin ${BUILDER_BUILDROOT_ORIGIN}
echo buildroot config ${BUILDER_BUILDROOT_CONFIG}

export VARIANT=${BUILDER_VARIANTS}	# FIXME: select variants

export OUTPUTDIR=output-${VARIANT}
export TOOLSDIR=/share/publish/xtensa/buildroot/${BUILDER_BUILDROOT_ORIGIN}/${BUILDER_BUILDROOT_CONFIG}/${VARIANT}/host/usr/bin

export PATH=$TOOLSDIR:$PATH

cd kernel

echo == Preparing for default configuration ${BUILDER_KERNEL_DEFCONFIG}

make O=$OUTPUT ARCH=xtensa CROSS_COMPILE=xtensa-linux- KBUILD_DEFCONFIG=${BUILDER_KERNEL_DEFCONFIG}_defconfig defconfig

echo == Building kernel

make O=$OUTPUT ARCH=xtensa CROSS_COMPILE=xtensa-linux-
