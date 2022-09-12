#!/usr/bin/awk BEGIN { for (i = 1; i <= ARGC; ++i) { gsub(/["$]/, "\\\\&", ARGV[i]); args = args " \"" ARGV[i] "\""; } system("env RUN= sh" args); }
[ -n "$RUN" ] || exec env RUN=1 flock -en "$0" sh "$0" "$@" # Run this script once
trap 'trap : TERM; kill 0; wait' INT TERM

readonly nftables_dir='/etc/nftables'
readonly nftables_bin_dir="${nftables_dir}/bin"
readonly ipv6_bogons_file="${nftables_dir}/ipv6.bogons"
readonly ipv4_bogons_file="${nftables_dir}/ipv4.bogons"

add_bogons() (
	cmd_file="${nftables_bin_dir}/generate-nft-${1}-element-adder.awk"
	[ -f "$cmd_file" ] && "$cmd_file" -v FAMILY="$2" -v TABLE="$3" -v SET="$4" -v FLUSH=1 "$5" > "$6" \
	&& nft --check --file "$6" && nft --file "$6"
)

curl --parallel --parallel-max 2 --fail --fail-early --retry "${1:-5}" --retry-max-time 0 --remove-on-error --location --create-dirs \
	--output "$ipv6_bogons_file" 'https://www.team-cymru.org/Services/Bogons/fullbogons-ipv6.txt' \
	--output "$ipv4_bogons_file" 'https://www.team-cymru.org/Services/Bogons/fullbogons-ipv4.txt' || exit

add_bogons ipv6 inet ingress_filter ipv6_bogons "$ipv6_bogons_file" "${nftables_dir}/add-ipv6-bogons.nft" &
add_bogons ipv4 inet ingress_filter ipv4_bogons "$ipv4_bogons_file" "${nftables_dir}/add-ipv4-bogons.nft" & wait
