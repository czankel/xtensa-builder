#!/bin/bash
cd buildroot
rm -fr output dl
ln -s ~/cache/buildroot-dl ./dl
make xtensa_fsf_defconfig
make
