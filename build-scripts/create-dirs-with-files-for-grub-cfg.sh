#!/bin/bash

# Set the proper path to project
cd /home/dawciobiel/IdeaProjects/hardclone/live-local-clonezilla

mkdir -p config/grub/isolinux
mkdir -p config/grub/boot/grub

chmod 755 config
chmod 755 config/grub
chmod 755 config/grub/isolinux
chmod 755 config/grub/boot
chmod 755 config/grub/boot/grub

chmod 644 config/grub/isolinux/grub.cfg
chmod 644 config/grub/boot/grub/grub.cfg

chown "$USER:$USER" -R config


tree -pug config
