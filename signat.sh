#!/bin/sh
#set CACFG

display_help() {
	echo "Usage : `basename $0` <server|client|codesign|email> <requete.csr>";
	exit;
};

if [ ! "$#" = "2" ]; then display_help; fi
case $1 in
	server|client) CACFG=tls;;
	codesign) CACFG=software;;
	email) CACFG=email;;
	*) display_help;;
esac
if [ ! -f "$2" ]; then
	echo "Fichier $2 introuvable";
	exit;
fi
if [ -f "${2%.csr}.crt" ]; then
	echo "Nom de certificat signé déjà utilisé";
	exit;
fi

openssl ca -config etc/nc-$CACFG-ca.conf -in "$2" -out "${2%.csr}.crt" -extensions $1_ext -notext

if [ -f "${2%.csr}.key" -a -f "${2%.csr}.crt" ]; then
	read -p "Convertir le certificat signé en PKCS#12 ? [y/n] ";
	if [ "${REPLY::1}" = "y" ]; then
		openssl pkcs12 -export -inkey "${2%.csr}.key" -in "${2%.csr}.crt" -out "${2%.csr}.p12";
	fi;
	cp "${2%.csr}."* /home/cert/
	read -p "Supprimer les fichiers locaux de cette certification ? [y/n] "
	if [ "${REPLY::1}" = "y" ]; then rm -f "${2%.csr}."*; fi
fi
