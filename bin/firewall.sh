#!/bin/sh

readonly nftables_dir='/etc/nftables'

read_nft_cmd() { nft --check --file "$1" && nft --file "$1"; }

read_nft_cmd "${nftables_dir}/nftables.nft" || exit
read_nft_cmd "${nftables_dir}/add-ipv6-bogons.nft"
read_nft_cmd "${nftables_dir}/add-ipv4-bogons.nft"

# Disable forwarding
sysctl --write net.ipv4.conf.all.forwarding=0
sysctl --write net.ipv6.conf.all.forwarding=0

# Netfilter settings for Synproxy
sysctl --write net.ipv4.tcp_syncookies=1
sysctl --write net.ipv4.tcp_timestamps=1
sysctl --write net.netfilter.nf_conntrack_tcp_loose=0
