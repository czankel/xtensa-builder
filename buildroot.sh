#!/bin/bash
cd buildroot
rm -fr output dl
ln -s /share/cache/buildroot/dl
make xtensa_fsf_defconfig
make
