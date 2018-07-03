#!/bin/sh

if [ -f "./lib.sh" ] ; then
	. ./lib.sh
else
	echo "lib.sh introuvable, démarrage impossible"
	exit 1
fi

if [ -f "${req_file%.csr}.key" -a -f "${req_file%.csr}.crt" ]; then
	read -p "Convertir le certificat signé en PKCS#12 ? [y/n] " R
	case "${R::1}" in
		y|Y|o|O) openssl pkcs12 -export -inkey "${req_file%.csr}.key" -in "${req_file%.csr}.crt" -out "${req_file%.csr}.p12" ;;
	esac
fi
