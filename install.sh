#!/bin/sh
readonly nftables_dir='/etc/nftables'
cd "${0%/*}" && rm -rf "$nftables_dir" && mkdir -p -m 700 "$nftables_dir" \
&& mv -f bin crontab nftables.nft "$nftables_dir" && ./bin/update-nft-bogons.sh
