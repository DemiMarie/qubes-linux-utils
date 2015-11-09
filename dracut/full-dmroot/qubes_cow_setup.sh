#!/bin/sh
#
# This file should be placed in pre-mount directory in dracut's initramfs, or
# scripts/local-top in case of initramfs-tools
#

# initramfs-tools (Debian) API
PREREQS=""
case "$1" in
    prereqs)
        # This runs during initramfs creation
        echo "$PREREQS"
        exit 0
        ;;
esac

# This runs inside real initramfs
if [ -r /scripts/functions ]; then
    # We're running in Debian's initramfs
    . /scripts/functions
    alias die=panic
    alias info=true
    alias warn=log_warning_msg
    alias log_begin=log_begin_msg
    alias log_end=log_end_msg
elif [ -r /lib/dracut-lib.sh ]; then
    . /lib/dracut-lib.sh
    alias log_begin=info
    alias log_end=true
else
    die() {
        echo "$@"
        exit 1
    }
    alias info=echo
    alias warn=echo
    alias log_begin=echo
    alias log_end=true
fi


info "Qubes initramfs script here:"

if ! grep -q 'root=[^ ]*dmroot' /proc/cmdline; then
    warn "dmroot not requested, probably not a Qubes VM"
    exit 0
fi

if [ -e /dev/mapper/dmroot ] ; then 
    die "Qubes: FATAL error: /dev/mapper/dmroot already exists?!"
fi

modprobe xenblk || modprobe xen-blkfront || warn "Qubes: Cannot load Xen Block Frontend..."

log_begin "Waiting for /dev/xvda* devices..."
while ! [ -e /dev/xvda ]; do sleep 0.1; done
log_end

if [ `cat /sys/block/xvda/ro` = 1 ] ; then
    log_begin "Qubes: Doing COW setup for AppVM..."

    while ! [ -e /dev/xvdc ]; do sleep 0.1; done
    VOLATILE_SIZE=$(sfdisk -s /dev/xvdc)
    ROOT_SIZE=$(sfdisk -s /dev/xvda) # kbytes
    SWAP_SIZE=1024 # kbytes
    if [ $VOLATILE_SIZE -lt $(($ROOT_SIZE + $SWAP_SIZE)) ]; then
        ROOT_SIZE=$(($VOLATILE_SIZE - $SWAP_SIZE))
    fi
    sfdisk -q --unit B /dev/xvdc >/dev/null <<EOF
0,$SWAP_SIZE,S
,$ROOT_SIZE,L
EOF
    if [ $? -ne 0 ]; then
        die "Qubes: failed to setup partitions on volatile device"
    fi
    while ! [ -e /dev/xvdc1 ]; do sleep 0.1; done
    mkswap /dev/xvdc1
    while ! [ -e /dev/xvdc2 ]; do sleep 0.1; done

    echo "0 `cat /sys/block/xvda/size` snapshot /dev/xvda /dev/xvdc2 N 16" | \
        dmsetup --noudevsync create dmroot || die "Qubes: FATAL: cannot create dmroot!"
    log_end
else
    log_begin "Qubes: Doing R/W setup for TemplateVM..."
    echo "0 `cat /sys/block/xvda/size` linear /dev/xvda 0" | \
        dmsetup --noudevsync create dmroot || die "Qubes: FATAL: cannot create dmroot!"
    log_end
fi
dmsetup mknodes dmroot
