#!/bin/bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPTDIR/chip_nand_scripts_common"

FEL=fel

INPUT_DIR="${1:-lib2}"

SPL="${INPUT_DIR}/sunxi-spl.bin"
UBOOT="${INPUT_DIR}/u-boot-dtb.bin"
UBOOT_SCRIPT="${UBOOT_SCRIPT:-${SCRIPTDIR}/gotofastboot.scr.bin}"

file_exists_or_quit() {
    if [[ ! -f "$1" ]]; then
        echo -e "\nERROR: file $1 does not exists\n\n"
        exit 1
    fi
}


file_exists_or_quit "${SPL}"
file_exists_or_quit "${UBOOT}"
file_exists_or_quit "${UBOOT_SCRIPT}"

#wait_for_fel
 
echo == upload the SPL to SRAM and execute it ==
"${FEL}" spl "${SPL}"

sleep 1 # wait for DRAM initialization to complete

echo == upload the main u-boot binary to DRAM ==
"${FEL}" -p write 0x4a000000 "${UBOOT}"

echo == upload the boot.scr file ==
"${FEL}" write 0x43100000 "${UBOOT_SCRIPT}"

echo == execute the main u-boot binary ==
"${FEL}" exe   0x4a000000
