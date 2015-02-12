#!/bin/sh
# Description: Generate custom auto install ISO
# Author: Xuan Ngo

### Extract ISO.
MOD_ISO_DIR=/media/sf_vm_sharedfolder/moddebdogdir
ISO_FILE_PATH=/media/sf_vm_sharedfolder/DebianDog-Wheezy-openbox_xfce.iso
./extract-deb-iso.sh ${ISO_FILE_PATH} ${MOD_ISO_DIR}

# Replace squashfs
SQUASHFS=${MOD_ISO_DIR}/live/01-filesystem.squashfs
NEW_SQUASHFS=/media/sf_vm_sharedfolder/01-remaster.squashfs
yes | cp ${NEW_SQUASHFS} ${SQUASHFS}


### Make ISO
DATE_STRING=`date +"%Y-%m-%d_%0k.%M.%S"`
OUTPUT_ISO_DIR=/media/sf_vm_sharedfolder
OUTPUT_ISO=${OUTPUT_ISO_DIR}/cust-debdog-${DATE_STRING}.iso

# Make ISO
rm -f ${OUTPUT_ISO}
genisoimage  -r -V "cust-deb-iso" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ${OUTPUT_ISO} ${MOD_ISO_DIR}


# Display info
echo "***************** Done *****************"
echo "Created ${OUTPUT_ISO}."