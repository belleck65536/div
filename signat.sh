#!/bin/sh
#set CACFG
#
# checker si nombre d'arguments = 2
#	then :checker existence de la conf en arg1 et checker existence de la csr en arg2


function display_help () {
	echo "Usage : $(basename $0) <configuration> <extensions> <requete>"
	exit
}

case "$#" in
	3)
		[ -f "$1" ] && cfg_file="$1" || ( echo "erreur sur fichier de configuration \"$1\"" ; exit )
		[ -f "$3" ] && req_file="$3" || ( echo "erreur sur fichier de requête \"$3\"" ; exit )
		[ -f "${req_file%.csr}.crt" ] && ( echo "Nom de certificat signé déjà utilisé \"${req_file%.csr}.crt\"" ; exit )
		[ $( grep -ec "\s*\[\s*${2}_ext\s*\]\s*" ) -ge 1 ] && exten="${2}_ext" || ( echo "extensions non trouvées \"$2\"" ; exit )
	;;
	0)
		# choisir configuration (une conf portant le même nom que les dossiers [dossier=cert promu CA] d'autorité signataire)
		# choisir requête (critères : extension .csr, pas de .crt associé)
		# assigner variable pour signature
	;;
	*)
		display_help
	;;
esac

openssl ca -config "$cfg_file" -in "$req_file" -out "${req_file%.csr}.crt" -extensions "$exten" -notext

if [ -f "${2%.csr}.key" -a -f "${2%.csr}.crt" ]; then
	read -p "Convertir le certificat signé en PKCS#12 ? [y/n] "
	[ "${REPLY::1}" = "y" ] && openssl pkcs12 -export -inkey "${2%.csr}.key" -in "${2%.csr}.crt" -out "${2%.csr}.p12"
	read -p "Supprimer les fichiers locaux de cette certification ? [y/n] "
	[ "${REPLY::1}" = "y" ] && rm -f "${2%.csr}."*
fi

cp "${2%.csr}."* /home/cert/
