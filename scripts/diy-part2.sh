#!/bin/bash
#
# Custom build steps after feeds are updated.
# Target: x86/64 main router, focused on stable OpenClash use.

set -e

echo "Fix rust CI download policy if rust feed is present"
if [ -f feeds/packages/lang/rust/Makefile ]; then
    sed -i 's/--set=llvm.download-ci-llvm=true/--set=llvm.download-ci-llvm=if-unchanged/' feeds/packages/lang/rust/Makefile
fi

echo "Add only the extra packages required by this build"
rm -rf kiddin9 package/community/luci-app-openclash package/community/luci-app-uugamebooster
git clone --depth=1 https://github.com/kiddin9/kwrt-packages kiddin9
mkdir -p package/community

if [ -d kiddin9/luci-app-openclash ]; then
    cp -rf kiddin9/luci-app-openclash package/community/luci-app-openclash
fi

if [ -d kiddin9/luci-app-uugamebooster ]; then
    cp -rf kiddin9/luci-app-uugamebooster package/community/luci-app-uugamebooster
fi

echo "Preset OpenClash core for x86_64"
chmod -R a+x "$GITHUB_WORKSPACE/scripts/preset-clash-core.sh"
if [ "$2" = "x86" ] || [ "$2" = "x86-23.05" ] || [ "$2" = "x86-24.10" ]; then
    "$GITHUB_WORKSPACE/scripts/preset-clash-core.sh" amd64
fi

cat >> .config <<'EOF'
# Keep the image focused: no all-kmods/devel build.
# CONFIG_ALL_KMODS is not set
# CONFIG_DEVEL is not set

# x86/64 image for direct upgrade on EFI systems.
CONFIG_TARGET_KERNEL_PARTSIZE=128
CONFIG_TARGET_ROOTFS_PARTSIZE=1024
CONFIG_TARGET_IMAGES_GZIP=y
CONFIG_GRUB_IMAGES=y
CONFIG_GRUB_EFI_IMAGES=y
# CONFIG_VMDK_IMAGES is not set
# CONFIG_TARGET_ROOTFS_EXT4FS is not set
CONFIG_TARGET_ROOTFS_SQUASHFS=y

# Main-router basics.
CONFIG_PACKAGE_dnsmasq-full=y
# CONFIG_PACKAGE_dnsmasq is not set
CONFIG_PACKAGE_ppp=y
CONFIG_PACKAGE_ppp-mod-pppoe=y
CONFIG_PACKAGE_luci-proto-ppp=y
CONFIG_PACKAGE_luci-proto-ipv6=y
CONFIG_PACKAGE_luci-app-firewall=y
CONFIG_PACKAGE_luci-app-upnp=y
CONFIG_PACKAGE_miniupnpd-nftables=y

# User requested proxy/game plugins.
CONFIG_PACKAGE_luci-app-openclash=y
CONFIG_PACKAGE_luci-app-passwall=y
CONFIG_PACKAGE_luci-app-ssr-plus=y
CONFIG_PACKAGE_luci-app-uugamebooster=y

# Useful management tools kept small.
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-compat=y
CONFIG_PACKAGE_luci-ssl=y
CONFIG_PACKAGE_luci-app-quickstart=y
CONFIG_PACKAGE_luci-app-ota=y
CONFIG_PACKAGE_luci-app-package-manager=y
CONFIG_PACKAGE_luci-app-ttyd=y
CONFIG_PACKAGE_luci-app-diskman=y
CONFIG_PACKAGE_luci-app-diskman_INCLUDE_lsblk=y
CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_lsblk=y
CONFIG_PACKAGE_parted=y
CONFIG_PACKAGE_e2fsprogs=y
CONFIG_PACKAGE_openssh-sftp-server=y

# Common x86 NIC/storage support for N100 boxes.
CONFIG_PACKAGE_kmod-igc=y
CONFIG_PACKAGE_kmod-e1000e=y
CONFIG_PACKAGE_kmod-igb=y
CONFIG_PACKAGE_kmod-r8125=y
CONFIG_PACKAGE_kmod-r8168=y
CONFIG_PACKAGE_kmod-usb-core=y
CONFIG_PACKAGE_kmod-usb2=y
CONFIG_PACKAGE_kmod-usb3=y
CONFIG_PACKAGE_kmod-usb-storage=y
CONFIG_PACKAGE_kmod-usb-storage-uas=y
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-vfat=y
CONFIG_PACKAGE_kmod-fs-exfat=y
CONFIG_PACKAGE_kmod-fs-ntfs3=y

# Networking helpers often needed by OpenClash/PassWall/SSR-Plus.
CONFIG_PACKAGE_kmod-tun=y
CONFIG_PACKAGE_kmod-nft-tproxy=y
CONFIG_PACKAGE_kmod-nft-socket=y
CONFIG_PACKAGE_kmod-nf-conntrack-netlink=y
CONFIG_PACKAGE_ip-full=y
CONFIG_PACKAGE_ipset=y
CONFIG_PACKAGE_iptables-nft=y
CONFIG_PACKAGE_ip6tables-nft=y
CONFIG_PACKAGE_ca-certificates=y
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_wget-ssl=y
CONFIG_PACKAGE_bash=y
CONFIG_PACKAGE_unzip=y
EOF
