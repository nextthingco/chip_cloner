#!/bin/bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPTDIR/chip_nand_scripts_common"

IMAGE_DIR="${1:-.}"
NAND_TYPE=${NAND_TYPE:-$2}
NAND_TYPE=${NAND_TYPE:-hynix-mlc}

echo "## NAND_TYPE = ${NAND_TYPE}"

SPL_IMAGE=spl-${NAND_TYPE}.bin
UBOOT_IMAGE=uboot-${NAND_TYPE}.bin
UBOOT_ENV_IMAGE=uboot-env-${NAND_TYPE}.bin
UBI_IMAGE=rootfs-${NAND_TYPE}.ubi.sparse
VID="-i 0x1f3a"

#UBOOT_SCRIPT="${SCRIPTDIR}/erasenand.scr.bin" "${SCRIPTDIR}/gotofastboot.sh" "${IMAGE_DIR}" || exit 1
UBOOT_SCRIPT="${SCRIPTDIR}/gotofastboot.scr.bin" "${SCRIPTDIR}/gotofastboot.sh" lib2 || exit 1
#UBOOT_SCRIPT="${SCRIPTDIR}/rawflash.scr.bin" "${SCRIPTDIR}/rawflash.sh" "${IMAGE_DIR}" || exit 1


fastboot ${VID} erase spl
fastboot ${VID} flash spl        "${IMAGE_DIR}/${SPL_IMAGE}"
fastboot ${VID} erase spl-backup
fastboot ${VID} flash spl-backup "${IMAGE_DIR}/${SPL_IMAGE}"
fastboot ${VID} erase uboot
fastboot ${VID} flash uboot      "${IMAGE_DIR}/${UBOOT_IMAGE}"
fastboot ${VID} erase env
fastboot ${VID} flash env        "${IMAGE_DIR}/${UBOOT_ENV_IMAGE}"
fastboot ${VID} erase UBI
fastboot ${VID} flash UBI        "${IMAGE_DIR}/${UBI_IMAGE}"
