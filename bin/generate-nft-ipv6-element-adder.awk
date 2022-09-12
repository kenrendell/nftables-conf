#!/usr/bin/awk -f

function normalize_ipv6_addr(ipv6_addr, n) {
	if (length(ipv6_addr) >= 40 || ipv6_addr ~ /(^:[^:]|[^:]:$|[^a-fA-F0-9:]|[^:]{5})/) return 0
	if (ipv6_addr ~ /::/) {
		if (ipv6_addr ~ /:::/ || ipv6_addr ~ /::[a-fA-F0-9:]+::/ || (n = 8 - gsub(/[a-fA-F0-9]+/, "&", ipv6_addr)) < 1) return 0
		sub(/::/, (ipv6_addr ~ /^:/ ? "" : ":") substr("0:0:0:0:0:0:0:0", 1, n * 2 - 1) (ipv6_addr ~ /:$/ ? "" : ":"), ipv6_addr)
	} return split(ipv6_addr, ipv6_addr_fields, ":") == 8
}

function check_cidr_mask(n, f) {
	if (f == 2) return (cidr_mask = n) ~ /^(12[0-8]|([1-9]|1[01])?[0-9])$/
	return f == 1 ? (cidr_mask = 128) : 0
}

BEGIN {
	FS = "/"; EXIT_CODE = 0; split("000 001 010 011 100 101 110 111", octbin, " ");
	if (FAMILY !~ /^(ip6|inet|netdev)$/ || TABLE !~ /^[_a-zA-Z][_a-zA-Z0-9]*$/ || SET !~ /^[_a-zA-Z][_a-zA-Z0-9]*$/) exit EXIT_CODE = 1
	for (i = 0; i < 16; ++i) hexbin[sprintf("%X", i)] = hexbin[sprintf("%x", i)] = int(i / 8) octbin[i % 8 + 1]
}

check_cidr_mask($2, NF) && normalize_ipv6_addr($1) {
	if (cidr_mask == 0) { prefixes[""] = ""; next; }
	prefix = ""; n = int((cidr_mask - 1) / 4);
	for (i = f = 0; i <= n; ++i) {
		if (i % 4 == 0) h = length(field = ipv6_addr_fields[++f]) - 4
		prefix = prefix hexbin[++h > 0 ? substr(field, h, 1) : 0]
	} prefixes[substr(prefix, 1, cidr_mask)] = ""
}

END {
	if (EXIT_CODE > 0) exit EXIT_CODE
	flush_set_cmd = (FLUSH == 1) ? sprintf("flush set %s %s %s\n", FAMILY, TABLE, SET) : ""
	printf("#!/usr/bin/nft --file\n" flush_set_cmd "add element %s %s %s {\n", FAMILY, TABLE, SET)
	if ("" in prefixes) printf("\t0:0:0:0:0:0:0:0/0,\n")
	else for (prefix in prefixes) {
		n = split(prefix, prefix_bits, "") - 1
		upper_prefix = ipv6_addr = ""
		for (i = dec = fail = 0; i <= n; ++i) {
			upper_prefix = upper_prefix (bit = prefix_bits[i + 1])
			if (i < n && (fail = upper_prefix in prefixes)) break
			if (i % 16 == 0 && i > 0) { ipv6_addr = (ipv6_addr != "" ? ipv6_addr ":" : "") sprintf("%X", dec); dec = 0; }
			if (bit) dec += 2 ^ (15 - i % 16)
		} if (fail) continue
		ipv6_addr = (ipv6_addr != "" ? ipv6_addr ":" : "") sprintf("%X", dec) substr(":0:0:0:0:0:0:0", 1, (7 - int(n / 16)) * 2)
		printf("\t%s/%s,\n", ipv6_addr, n + 1)
	} printf("}\n")
}
