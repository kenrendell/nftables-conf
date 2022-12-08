#!/bin/sh
readonly nftables_dir='/etc/nftables'
cd "${0%/*}" && rm -rf "$nftables_dir" && mkdir -p "$nftables_dir" \
&& cp -r bin nftables.nft "$nftables_dir" && ./bin/update-nft-bogons.sh
