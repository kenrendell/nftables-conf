#!/bin/sh

readonly nftables_dir='/etc/nftables' conntrack_max

read_nft_cmd() { nft --check --file "$1" && nft --file "$1"; }

# Disable forwarding
printf '0\n' > /proc/sys/net/ipv4/conf/all/forwarding
printf '0\n' > /proc/sys/net/ipv6/conf/all/forwarding

# Netfilter settings for Synproxy
printf '1\n' > /proc/sys/net/ipv4/tcp_syncookies
printf '1\n' > /proc/sys/net/ipv4/tcp_timestamps
printf '0\n' > /proc/sys/net/netfilter/nf_conntrack_tcp_loose

if read_nft_cmd "${nftables_dir}/nftables.nft"; then
	read_nft_cmd "${nftables_dir}/add-ipv6-bogons.nft"
	read_nft_cmd "${nftables_dir}/add-ipv4-bogons.nft"
fi
