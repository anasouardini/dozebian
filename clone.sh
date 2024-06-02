#!/bin/sh

if [ "$1" = "preseed" ]; then
  bash ./preseed.sh;
elif [ "$1" = "vm" ]; then
  bash ./create-vm.sh;
else
  bash ./preseed.sh && bash ./create-vm.sh;
fi

