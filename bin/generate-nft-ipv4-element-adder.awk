#!/usr/bin/awk -f

function check_cidr_mask(n, f) {
	if (f == 2) return (cidr_mask = n) ~ /^([12]?[0-9]|3[0-2])$/
	return f == 1 ? (cidr_mask = 32) : 0
}

BEGIN {
	FS = "/"; EXIT_CODE = 0;
	if (FAMILY !~ /^(ip|inet|netdev)$/ || TABLE !~ /^[_a-zA-Z][_a-zA-Z0-9]*$/ || SET !~ /^[_a-zA-Z][_a-zA-Z0-9]*$/) exit EXIT_CODE = 1
}

check_cidr_mask($2, NF) && $1 "." ~ /^((25[0-5]|([1-9]|1[0-9]|2[0-4])?[0-9])\.){4}$/ {
	prefix = ""; split($1, ipv4_addr_fields, ".");
	for (i = f = 0; i < cidr_mask; ++i) {
		if (i % 8 == 0) dec = ipv4_addr_fields[++f]
		if (dec < (bit_value = 2 ^ (7 - i % 8))) prefix = prefix "0"
		else { prefix = prefix "1"; dec -= bit_value; }
	} prefixes[prefix] = ""
}

END {
	if (EXIT_CODE > 0) exit EXIT_CODE
	flush_set_cmd = (FLUSH == 1) ? sprintf("flush set %s %s %s\n", FAMILY, TABLE, SET) : ""
	printf("#!/usr/bin/nft --file\n" flush_set_cmd "add element %s %s %s {\n", FAMILY, TABLE, SET)
	if ("" in prefixes) printf("\t0.0.0.0/0,\n")
	else for (prefix in prefixes) {
		n = split(prefix, prefix_bits, "") - 1
		upper_prefix = ipv4_addr = ""
		for (i = dec = fail = 0; i <= n; ++i) {
			upper_prefix = upper_prefix (bit = prefix_bits[i + 1])
			if (i < n && (fail = upper_prefix in prefixes)) break
			if (i % 8 == 0 && i > 0) { ipv4_addr = (ipv4_addr != "" ? ipv4_addr "." : "") dec; dec = 0; }
			if (bit) dec += 2 ^ (7 - i % 8)
		} if (fail) continue
		ipv4_addr = (ipv4_addr != "" ? ipv4_addr "." : "") dec substr(".0.0.0", 1, (3 - int(n / 8)) * 2)
		printf("\t%s/%s,\n", ipv4_addr, n + 1)
	} printf("}\n")
}
