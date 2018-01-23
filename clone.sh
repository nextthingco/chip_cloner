#!/bin/bash

function require() { [[ -z "$(which $1)" ]] && echo "ERROR: cannot find '$1' please install!" && exit 1; }

function require_docker_image { docker inspect $1 >/dev/null || \
    docker pull $1 || \
    (echo "ERROR: cannot obtain $1" && exit 1);
}

function docker_run() {
docker run --rm  -it -v $PWD:/work -w /work -u $UID:$UID $@
}

function main() {
    local retry=60
    local HOWITZER_IMAGE=ntc-registry.githost.io/gadget/howitzer-container:master
    #local CHIP_NAND_SCRIPTS_IMAGE=ntc-registry.githost.io/nextthingco/chip-nand-scripts:unstable
    local CHIP_NAND_SCRIPTS_IMAGE=chip-nand-scripts


    require curl
    require docker

    require_docker_image $HOWITZER_IMAGE
    require_docker_image $CHIP_NAND_SCRIPTS_IMAGE

    echo -n "Waiting for device..."
    while true; do
        [[ "$retry" -le "0" ]] && echo "TIMEOUT" && exit 1;

        curl --connect-timeout 3 192.168.81.1:8080/info 2>/dev/null&& break
        retry=$((retry - 1))
        sleep 1;
        echo -n  "."
    done
    echo "OK"

    echo "Downloading rootfs.tar"
    curl 192.168.81.1:8080/backup >rootfs.tar
    local ROOTFS=rootfs.tar

    local DOCKER_CMD=""

    local NAND_CONFIG=${NAND_CONFIG:-$1}
    local NAND_CONFIG=${NAND_CONFIG:-hynix-mlc}

    docker_run $CHIP_NAND_SCRIPTS_IMAGE mk_chip_image $NAND_CONFIG spl         /opt/CHIP-u-boot/spl/sunxi-spl.bin         spl-$NAND_CONFIG.bin
    docker_run $CHIP_NAND_SCRIPTS_IMAGE mk_chip_image $NAND_CONFIG u-boot      /opt/CHIP-u-boot/u-boot-dtb.bin            uboot-$NAND_CONFIG.bin
    docker_run $CHIP_NAND_SCRIPTS_IMAGE mk_chip_image $NAND_CONFIG u-boot-env ./uboot-env.txt                             uboot-env-$NAND_CONFIG.bin
    docker_run $CHIP_NAND_SCRIPTS_IMAGE mk_chip_image $NAND_CONFIG ubifs      $ROOTFS                                     rootfs-$NAND_CONFIG.ubifs
    docker_run $CHIP_NAND_SCRITPS_IMAGE mk_chip_image $NAND_CONFIG ubi        rootfs-$NAND_CONFIG.ubifs                   rootfs-$NAND_CONFIG.ubi

    rm -f fel.chp
    rm -f fastboot.chp
    docker_run $HOWITZER_IMAGE ./flash.sh

    local OUTPUT_CHP=image.chp
    rm -f "$OUTPUT_CHP"
    docker_run $HOWITZER_IMAGE howitzer nand $NAND_CONFIG chp fel.chp chp fastboot.chp -f "${OUTPUT_CHP}"

}

main $@
