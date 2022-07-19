#!/sbin/sh
#
# RMM State Remover for Samsung Devices
# Original idea by BlackMesa123 @XDA developers, updated by _alexndr @XDA developers
# to add support modern Samsung devices with separate /vendor partition
#

OUTFD=$2

# Detect real $OUTFD
readlink /proc/$$/fd/$OUTFD 2>/dev/null | grep /tmp >/dev/null
if [ $? -eq 0 ] ; then
    OUTFD=0
    for FD in `ls /proc/$$/fd` ; do
        readlink /proc/$$/fd/$FD 2>/dev/null | grep pipe >/dev/null
        if [ $? -eq 0 ] ; then
            ps | grep " 3 $FD " | grep -v grep >/dev/null
            if [ $? -eq 0 ] ; then
                OUTFD=$FD
                break
            fi
        fi
    done
fi

ui_print() {
    echo -n -e "ui_print $1\n" >> /proc/self/fd/$OUTFD
    echo -n -e "ui_print\n" >> /proc/self/fd/$OUTFD
}

resolve_link() {
    if [ -z "$1" ] || [ ! -e $1 ] ; then return 1 ; fi
    local VAR=$1
    while [ -L $VAR ] ; do
        VAR=$(readlink $VAR)
    done
    echo $VAR
}

is_mounted() {
    if [ -z "$2" ] ; then
        cat /proc/mounts | grep "$1" >/dev/null
    else
        cat /proc/mounts | grep "$1" | grep "$2," >/dev/null
    fi
    return $?
}

SYSTEM=$(resolve_link $(find /dev/block/platform -type l -iname system))
VENDOR=$(resolve_link $(find /dev/block/platform -type l -iname vendor))

ui_print " "
ui_print "*******************************************"
ui_print "   RMM State Remover for Samsung Devices   "
ui_print "      by BlackMesa123 @XDA developers      "
ui_print "   (updated by _alexndr @XDA developers)   "
ui_print "*******************************************"

ui_print "- Mounting /system..."
(! is_mounted /system) && mount /system
(! is_mounted /system rw) && mount -o rw,remount /system
(! is_mounted /system) && mount -t auto $SYSTEM /system
if (! is_mounted /system) ; then
    ui_print "Failed! Can't mount /system, aborting!"
    ui_print " "
    exit 1
fi

if [ ! -z "$VENDOR" ] ; then
    ui_print "- Mounting /vendor..."
    (! is_mounted /vendor) && mount /vendor
    (! is_mounted /vendor rw) && mount -o rw,remount /vendor
    if (! is_mounted /vendor) ; then
        mkdir -p /vendor
        mount -t auto $VENDOR /vendor
    fi
    if (! is_mounted /vendor) ; then
        ui_print "Failed! Can't mount /vendor, aborting!"
        ui_print " "
        exit 1
    fi
fi

ui_print "- Applying Bypass/Fix..."
sed -i 's/vaultkeeper.feature=1/vaultkeeper.feature=0/g' /system/build.prop 2>/dev/null
sed -i 's/vaultkeeper.feature=1/vaultkeeper.feature=0/g' /vendor/build.prop 2>/dev/null
rm -Rf /system/priv-app/Rlc 2>/dev/null

ui_print "- Unmounting /system..."
umount /system
(is_mounted /vendor) && ui_print "- Unmounting /vendor..."
umount /vendor 2>/dev/null

ui_print "*******************************************"
ui_print "               Done! Enjoy :D              "
ui_print "*******************************************"
ui_print " "

exit 0
