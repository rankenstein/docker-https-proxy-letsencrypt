#!/bin/bash

containsElement () {
	local e
	for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
	return 1
}

cd /usr/local/apache2/ssl

hosts=()
for i in ${!HOST_*}; do
	hosts+=("$(echo "${i#HOST_}" | sed -e s/_/./g)")
done

args=(-f account_key.json -f cert.pem -f chain.pem -f key.pem --default_root /usr/local/apache2/htdocs)

for i in "${hosts[@]}"; do
	args+=(-d "$i")
done

if [ ! -z "$ACME_EMAIL" ]; then
	args+=(--email "$ACME_EMAIL")
fi

echo "simp_le ${args[@]}"

simp_le "${args[@]}"
