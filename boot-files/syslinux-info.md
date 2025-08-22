# SYSLINUX

Since Syslinux 6.00, the respective binary files (e.g. boot loaders, installers, Syslinux modules,...) are located under respective "/bios/", "/efi32/", "/efi64/" subdirectories in the official Syslinux archives.

Official Testing versions (aka pre-release), when available, can be downloaded from:

https://www.kernel.org/pub/linux/utils/boot/syslinux/Testing/ 

The latest official version of Syslinux can be downloaded in .tar.gz, .tar.bz2, .tar.xz, and .zip formats from [kernel.org](<https://www.kernel.org/pub/linux/utils/boot/syslinux/>). This download includes both the source and official pre-compiled binaries that should work for most users (see also [Official Binaries](<https://wiki.syslinux.org/wiki/index.php?title=Common_Problems#Official_Binaries>)). Version changes are available in the .LSM files.

The Syslinux download includes PXELINUX, ISOLINUX and MEMDISK as well. 


## WARNING

At least SuSE, Mandriva, and Ubuntu use a version of SYSLINUX modified with a patch called "gfxboot". This is a highly invasive and unsupported modification of SYSLINUX. Please avoid these versions if possible. 
