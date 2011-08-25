#!/bin/bash

echo component ${BUILDER_COMPONENT}
echo variant ${BUILDER_VARIANT}
echo built-in variants ${BUILDER_BUILTIN_VARIANTS}
echo kernel defconfig ${BUILDER_KERNEL_DEFCONFIG}
echo buildroot origin ${BUILDER_BUILDROOT_ORIGIN}
echo buildroot config ${BUILDER_BUILDROOT_CONFIG}


#cd $1
#rm -fr output
#make O=output ARCH=xtensa CROSS_COMPILE=$BUILDER_CROSS_COMPILE KBUILD_DEFCONFIG=$BUILDER_DEFCONFIG defconfig
##make O=output ARCH=xtensa CROSS_COMPILE=$BUILDER_CROSS_COMPILE
