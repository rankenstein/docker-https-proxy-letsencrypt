#!/bin/bash

containsElement () {
	local e
	for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
	return 1
}

esc() {
	ret=( )
	for i in "$@"; do
		ret+=( "$(printf '%q' "$i")" )
	done
	echo "${ret[@]}"
}

cd /usr/local/apache2/ssl

simple=(simp_le -f account_key.json -f cert.pem -f chain.pem -f key.pem --default_root /usr/local/apache2/htdocs)

if [ ! -z "$ACME_EMAIL" ]; then
	simple+=(--email "$ACME_EMAIL")
fi

commands=""
for i in ${!HOST_*}; do
	id="${i#HOST_}"
	host="$(echo "$id" | sed -e s/__/-/g | sed -e s/_/./g)"

	[ ! -e "$host" ] && mkdir "$host"

	if [ ! -e account_key.json ]; then
		cd "$host" || continue

		echo "${simple[@]}" -d "$host"
		"${simple[@]}" -d "$host" || exit $?
		mv account_key.json ..
		ln -s ../account_key.json
		cd ..
	else
		[ ! -e "$host/account_key.json" ] && ln -s ../account_key.json "$host/"

		commands="$(echo "$commands"; echo "cd $(esc "$host") && echo "$(esc "${simple[@]}" -d "$host")" && $(esc "${simple[@]}" -d "$host")")"
	fi
done

if [ ! -z "$commands" ]; then
	echo "$commands" | parallel -j5
fi
