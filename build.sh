#!/bin/bash

# set default jobs and threads
CPUS=`grep -c processor /proc/cpuinfo`
JOBS="$(( ${CPUS} * 3 / 2))"
THREADS="$(( ${CPUS} * 2 ))"

PROGNAME=build.sh
MACHINE=raspberrypi4-64

ROOTDIR=$(readlink -f $BASH_SOURCE | xargs dirname)
DOWNLOADS="$ROOTDIR/downloads"
CACHES="$ROOTDIR/sstate-cache"
PROJECT_DIR=$ROOTDIR/output_$MACHINE

[ -e $DOWNLOADS ] || mkdir -p $DOWNLOADS
[ -e $CACHES ] || mkdir -p $CACHES
[ -e $PROJECT_DIR ] || mkdir -p $PROJECT_DIR

if [ ! -e $PROGNAME ]; then
	echo "Please jump to $PROGNAME directory"
	return
fi

cd poky
set -- $PROJECT_DIR
source oe-init-build-env

sed -i -e '/^#.*/d' -e '/^$/d' conf/local.conf
sed -e "s,MACHINE ??=.*,MACHINE ??= '$MACHINE',g" -i conf/local.conf

cat >> conf/local.conf <<-EOF

# Parallelism Options
BB_NUMBER_THREADS = "$THREADS"
PARALLEL_MAKE = "-j $JOBS"
DL_DIR = "$DOWNLOADS"
SSTATE_DIR = "$CACHES"
# export BB_NO_NETWORK = "1"
EOF

LAYER_LIST="
poky/meta
poky/meta-poky
poky/meta-yocto-bsp
meta-raspberrypi
meta-openembedded/meta-oe
meta-openembedded/meta-python
meta-openembedded/meta-multimedia
meta-openembedded/meta-networking
meta-myrpi
"

# add layers
for layer in $(eval echo $LAYER_LIST); do
    append_layer=""
    if [ -e ${ROOTDIR}/${layer} ]; then
        append_layer="${ROOTDIR}/${layer}"
    fi
    if [ -n "${append_layer}" ]; then
        append_layer=`readlink -f $append_layer`
	bitbake-layers add-layer $append_layer
    fi
done

#time bitbake core-image-base
#time bitbake core-image-base -c populate_sdk

#cd ~/yocto/poky/rpi-build/tmp/deploy/sdk
#sudo ./poky-glibc-x86_64-core-image-base-cortexa72-raspberrypi4-64-toolchain-3.2.1.sh
#source /opt/poky/3.2.1/environment-setup-cortexa72-poky-linux
