#!/bin/bash

TOP_DIR=./
S2L_LINUX_SDK_DIR=$TOP_DIR/s2l_linux_sdk
AMBA_PATCH_DIR=$TOP_DIR/$S2L_LINUX_SDK_DIR/s2l_2.6.0_20180208/
HAWTHORN_DIR=$TOP_DIR/$S2L_LINUX_SDK_DIR/ambarella/boards/hawthorn/
SL2M_IRONMAN_DIR=$TOP_DIR/$S2L_LINUX_SDK_DIR/ambarella/boards/s2lm_ironman/
KERNEL_DTSI_DIR=ambarella/kernel/linux-3.10/arch/arm/boot/dts/
AK7755_DRIVE_CODE_DIR=ambarella/kernel/linux-3.10/sound/soc/codecs/

AK7755_DTSI_FILE=ak7755_and_dtsi.tar.gz
AMBA_SDK_NAME=s2l_linux_sdk_20150928.tar.xz
AMBA_PATCH_NAME=s2l_2.6.0_20180208.tar.bz2
AONI_PATCH_NAME=Aoni_To_IV_20190327.patch


echo "Patch for IV"
echo "Installation steps:"
echo "1. Unzip Amba's SDK version 2.6 "
echo "2. Run the Amba's patch"
echo "3. Run the Aoni's patch"
echo "4. Compile the SDK"

echo "+++++++++++++ Running the first step +++++++++++++"
tar xJf $AMBA_SDK_NAME
rm $AMBA_SDK_NAME
mv $AMBA_PATCH_NAME $S2L_LINUX_SDK_DIR
mv $AONI_PATCH_NAME $S2L_LINUX_SDK_DIR
mv $AK7755_DTSI_FILE $S2L_LINUX_SDK_DIR

pushd $HAWTHORN_DIR
source ../../build/env/Linaro-multilib-gcc4.9.env
make sync_build_mkcfg
make s2l_ipcam_config
popd

echo "+++++++++++++ Running the second step +++++++++++++"
pushd $S2L_LINUX_SDK_DIR
tar xjf $AMBA_PATCH_NAME
rm $AMBA_PATCH_NAME
popd

pushd $AMBA_PATCH_DIR
chmod +x apply.sh
./apply.sh
popd

echo "+++++++++++++ Running the third step +++++++++++++"
pushd $S2L_LINUX_SDK_DIR
patch -p1 < $AONI_PATCH_NAME
tar -xvf $AK7755_DTSI_FILE
echo "mv ak7755 code and s2l dtsi to kernel"
rm $KERNEL_DTSI_DIR/ambarella-s2l.dtsi
mv ak7755_and_dtsi/ambarella-s2l.dtsi $KERNEL_DTSI_DIR
rm $AK7755_DRIVE_CODE_DIR/ak7755*
mv ak7755_and_dtsi/ak7755* $AK7755_DRIVE_CODE_DIR
mv ak7755_and_dtsi/AK7755* $AK7755_DRIVE_CODE_DIR
echo "mv done"
chmod 755 ambarella/build/dtc -R
rm $AONI_PATCH_NAME
rm $AK7755_DTSI_FILE
rm ak7755_and_dtsi -fr 
rm s2l_2.6.0_20180208 -fr
popd

echo "+++++++++++++ Running the fourth step +++++++++++++"
pushd $SL2M_IRONMAN_DIR
source ../../build/env/armv7ahf-linaro-gcc.env
chmod 777 rootfs/default/etc/init.d/S11init
make distclean
make clean
make sync_build_mkcfg
make s2lm_ironman_config
make defconfig_public_linux 
make -j 8
popd

echo "DONE"