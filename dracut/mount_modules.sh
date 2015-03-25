#
# This file should be places in pre-pivot directory in dracut's initramfs
#

#!/bin/sh

if ! [ -d $NEWROOT/lib/modules/`uname -r` ]; then
    echo "Waiting for /dev/xvdd device..."
    while ! [ -e /dev/xvdd ]; do sleep 0.1; done

    mount -n -t ext3 /dev/xvdd $NEWROOT/lib/modules
fi

