# creating and starting the network vmnet
# if it does exist, It'll throw a little error, no big deal
sudo virsh net-define --file vmnet.xml
sudo virsh net-start vmnet

Nname=vmnet
dName=autodeb3

## removing old domain
sudo virsh shutdown $dName 
sudo virsh destroy $dName 
sudo virsh undefine --nvram $dName

iso=~/home/iso/DEBIAN_ISO_WORKDIR/debian11-net-preseeded.iso \
# iso=~/home/iso/debian11-net.iso \

sudo virt-install \
  --virt-type kvm \
  --name $dName \
  --cdrom $iso \
  --os-variant debiantesting \
  --disk ~/home/vms/$dName.img,size=5 \
  --check path_in_use=off \
  --memory 2048 \
  --filesystem ~/home/vms/,sdv,type='mount',mode='mapped' \
  --vcpus 4 \
  --cpu host-passthrough,cache.mode=passthrough \
  --network network=$Nname,model=virtio-net-pci


