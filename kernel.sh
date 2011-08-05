#!/bin/bash

echo component ${BUILDER_COMPONENT}
echo config name ${BUILDER_CONFIG_NAME}
echo config file ${BUILDER_CONFIG_FILE}


#cd $1
#rm -fr output
#make O=output ARCH=xtensa CROSS_COMPILE=$BUILDER_CROSS_COMPILE KBUILD_DEFCONFIG=$BUILDER_DEFCONFIG defconfig
##make O=output ARCH=xtensa CROSS_COMPILE=$BUILDER_CROSS_COMPILE
