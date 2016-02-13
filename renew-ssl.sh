#!/bin/bash

containsElement () {
	local e
	for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
	return 1
}

cd /ssl/letsencrypt

hosts=()
for i in ${!HOST_*}; do
	hosts+=("$(echo "${i#HOST_}" | sed -e s/_/./g)")
done

if [ ! -e cert.pem ]; then
	echo "Certificate does not exist, creating."
else

	date_cert="$(date --date="$(openssl x509 -startdate -in cert.pem -noout | cut -d= -f2)" +%s)"
	date_now="$(date +%s)"
	days_old="$[($date_now-$date_old)/86400]"

	if [ "$days_old" -gt 30 ]; then
		echo "Certificate $days_old days old, recreating."
	else
		IFSb="$IFS"
		IFS=", "
		san=$(openssl x509 -text -in cert.pem -noout | grep -A1 'X509v3 Subject Alternative Name:' | tail -1)
		IFS="$IFSb"

		missing_hosts=()
		for i in "${hosts[@]}"; do
			if ! containsElement "DNS:$i" "${san[@]}"; then
				missing_hosts+=("$i")
			fi
		done

		if [ "${#missing_hosts[@]}" -gt 0 ]; then
			echo "Missing SAN hosts ${missing_hosts[@]}. Recreating certificate."
		else
			echo "Certificate is $days_old days old. Not recreating."
			exit 0
		fi
	fi
fi

args=(-f account_key.json -f cert.pem -f chain.pem -f key.pem --default_root /usr/local/apache2/htdocs)

for i in "${hosts[@]}"; do
	args+=(-d "$i")
done

if [ ! -z "$ACME_EMAIL" ]; then
	args+=(--email "$ACME_EMAIL")
fi

echo "simp_le ${args[@]}"

simp_le "${args[@]}"
