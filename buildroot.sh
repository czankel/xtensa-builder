#!/bin/bash
# BUILDER_COMPONENT		- buildroot
# BUILDER_CONFIG_FILE		- configuration file name (can be empty)
# BUILDER_CONFIG_NAME		- configuration name

cd buildroot
rm -fr output dl
ln -s /share/cache/buildroot/dl

if [ ${BUILDER_CONFIG_FILE} -ne "" ]
then
	cp builder/buildroot-defconfig/${BUILDER_CONFIG_FILE} buildroot/output/.defconfig
	make defconfig
else
	make ${BUILDER_CONFIG_NAME}
fi
make

