#!/bin/bash -xe

DATA_STATE="unknown";
until [ "$DATA_STATE" == "disk" ]; do
  DATA_STATE=$(sudo lsblk --noheadings --output TYPE /dev/sdh);
  echo $DATA_STATE;
  sleep 5;
done;

DATA_FILESYSTEM="$(blkid /dev/sdh)";
if [ "$DATA_FILESYSTEM" = "" ]; then
  mkfs -t ext4 /dev/sdh;
fi

echo "/dev/sdh /data ext4 defaults,noatime 0 0" >> /etc/fstab;
mkdir /data;
mount -a;

if [ "$DATA_FILESYSTEM" = "" ]; then
  mkdir /data/postgres /data/redis;
fi

chown -R ec2-user:ec2-user /data;
