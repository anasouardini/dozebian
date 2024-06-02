#!/bin/bash 

#Source: https://gist.github.com/akatch/3669d3044b7d04677704

COMMON_PATH=$HOME/home
ISO_NAME=debian11-net
RAW_DEBIAN_ISO=$COMMON_PATH/iso/$ISO_NAME.iso
WORKDIR=$COMMON_PATH/iso/DEBIAN_ISO_WORKDIR
PRESEED_FILE=$COMMON_PATH/scripts/autodebian/preseed.cfg
PRESEED_ISO=$WORKDIR/$ISO_NAME-preseeded.iso

function preseed(){
  ##### Scrub workdir
  sudo rm -rf $WORKDIR/*

  #### Mount image
  mkdir -p $WORKDIR/loopdir
  sudo mount -o loop $RAW_DEBIAN_ISO $WORKDIR/loopdir/

  #### Copy extracted/mounted image
  mkdir -p $WORKDIR/isodir

  cp -rT $WORKDIR/loopdir $WORKDIR/isodir
  sudo umount $WORKDIR/loopdir
  sudo rm -rf $WORKDIR/loopdir/

  #### copy preseed.cfg to the root of the iso
  sudo cp preseed.cfg $WORKDIR/isodir

  #### copy post installation script to the iso
  sudo cp $HOME/home/scripts/installer.sh $WORKDIR/isodir/postinstall.sh
  sudo chown venego:venego $WORKDIR/isodir/postinstall.sh
  sudo chmod 770 $WORKDIR/isodir/postinstall.sh

  #### auto menu select
  sudo sed -i 's/vesamenu.c32/install/' $WORKDIR/isodir/isolinux/isolinux.cfg
  sudo sed -i 's/append/append auto=true file=\/cdrom\/preseed.cfg/' $WORKDIR/isodir/isolinux/txt.cfg
  # remove grub menu
  sudo chmod +w $WORKDIR/isodir/boot/grub/grub.cfg
  sudo printf '\nset timeout=0' >> $WORKDIR/isodir/boot/grub/grub.cfg
  sudo chmod -w $WORKDIR/isodir/boot/grub/grub.cfg

  #### Fix md5sum
  cd $WORKDIR/isodir 
  sudo chmod +w md5sum.txt
  find -follow -type f ! -name md5sum.txt -print0 | xargs -0 md5sum > md5sum.txt
  sudo chmod -w md5sum.txt
  cd ..

  ##### Create ISO
  sudo chmod +w $WORKDIR/isodir/isolinux/isolinux.bin
  genisoimage -r -J -b isolinux/isolinux.bin -c isolinux/boot.cat \
            -no-emul-boot -boot-load-size 4 -boot-info-table \
            -o $PRESEED_ISO $WORKDIR/isodir/
  sudo chmod -w $WORKDIR/isodir/isolinux/isolinux.bin

  # sudo rm -rf $WORKDIR/isodir/

}
preseed;

exit 0
