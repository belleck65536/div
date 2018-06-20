#!/bin/sh
#
# -c "config_file" -e "extension" -i "req_file"

. ./select.sh

function display_help () {
	echo "Usage : $(basename $0) <configuration> <extensions> <requete>"
	exit
}

while getopts ":c:e:i:" opt; do
	case $opt in
		c)
			[ -f "$OPTARG" ] && cfg_file="$OPTARG" || ( echo "erreur sur fichier de configuration \"$OPTARG\"" ; exit 1 )
		;;
		e)
			exten="$OPTARG"
		;;
		i)
			[ -f "$OPTARG" ] && req_file="$OPTARG" || ( echo "erreur sur fichier de requête \"$OPTARG\"" ; exit 1 )
		;;
		\?)
			echo "Invalid option: -$OPTARG" ; display_help
		;;
		:)
			echo "Option -$OPTARG requires an argument." ; display_help
		;;
	esac
done

# validation i
[ -z "$req_file" ] && # choisir req_file dans une liste excluant les csr ayant un crt, si liste vide, renvoyer un message d'erreur + sortie
#[ -f "${req_file%.csr}.crt" ] && ## choisir à nouveau					( echo "Nom de certificat signé déjà utilisé \"${req_file%.csr}.crt\"" ; exit 1 )

# validation c
[ -z "$cfg_file" ] && # choisir config, si liste vide, sortir

# validation e
[ -z "$exten" -o $( grep -ec "\s*\[\s*$2\s*\]\s*" ) -lt 1 ] && # choisir extensions dans config
si exten toujours vide, quitter sur anomalie extension dans config_file


openssl ca -config "$cfg_file" -in "$req_file" -out "${req_file%.csr}.crt" -extensions "$exten" -notext

if [ -f "${req_file%.csr}.key" -a -f "${req_file%.csr}.crt" ]; then
	read -p "Convertir le certificat signé en PKCS#12 ? [y/n] "
	[ "${REPLY::1}" = "y" ] && openssl pkcs12 -export -inkey "${req_file%.csr}.key" -in "${req_file%.csr}.crt" -out "${req_file%.csr}.p12"
	read -p "Supprimer les fichiers locaux de cette certification ? [y/n] "
	[ "${REPLY::1}" = "y" ] && rm -f "${req_file%.csr}."*
fi

cp "${req_file%.csr}."* /home/cert/
