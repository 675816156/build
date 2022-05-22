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
meta-raspberrypi
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

time tsocks bitbake core-image-minimal

