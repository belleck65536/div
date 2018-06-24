#!/bin/sh
#
# signat.sh -c "config_file" -e "extension" -i "req_file"

. ./select.sh

CSRDIR=req
CFGDIR=etc

function display_help () {
	echo "Usage : $(basename $0) <configuration> <extensions> <requete>"
	exit
}

while getopts ":c:e:i:" opt; do
	case $opt in
		c) [ -f "$OPTARG" ] && cfg_file="$OPTARG" || ( echo "erreur sur fichier de configuration \"$OPTARG\"" ; exit 1 ) ;;
		i) [ -f "$OPTARG" ] && req_file="$OPTARG" || ( echo "erreur sur fichier de requête \"$OPTARG\"" ; exit 1 ) ;;
		e) exten="$OPTARG" ;;
		\?) echo "Invalid option: -$OPTARG" ; display_help ;;
		:) echo "Option -$OPTARG requires an argument." ; display_help ;;
	esac
done

# validation i
# si pas d'argument fourni, on recherche une CSR
[ -z "$req_file" ] && slct $( for csr in $CSRDIR/*.csr ; do [ ! -f "${csr%.csr}.crt" ] && echo "$csr" ; done  )
# si on a toujours pas d'arguments, c'est qu'il n'y avait rien en entrée et que la sélection n'a rien donné (pas de résultat/tout est signé)
[ -z "$req_file" ] && ( echo "aucune requête disponible pour être signée" ; exit 1 )
# si le CRT asocié existe, on sort car cette vérif a été exécuté lors de la selection des requêtes.
# ce test ne sert que pour l'utilsation avec arguments
[ -f "${req_file%.csr}.crt" ] && ( echo "Nom de certificat signé déjà utilisé \"${req_file%.csr}.crt\"" ; exit 1 )

# validation c
[ -z "$cfg_file" ] && slct $( ls *-ca/*.conf )
# choisir config, si liste vide, sortir
[ -z "$cfg_file" ] && ( echo "aucune configuration disponible pour signer la requête" ; exit 1 )

# validation e
[ -z "$exten" -o $( grep -ec "\s*\[\s*$2\s*\]\s*" ) -lt 1 ] && # choisir extensions dans config
si exten toujours vide, quitter sur anomalie extension dans config_file


echo openssl ca -config "$cfg_file" -in "$req_file" -out "${req_file%.csr}.crt" -extensions "$exten" -notext

if [ -f "${req_file%.csr}.key" -a -f "${req_file%.csr}.crt" ]; then
	read -p "Convertir le certificat signé en PKCS#12 ? [y/n] "
	[ "${REPLY::1}" = "y" ] && openssl pkcs12 -export -inkey "${req_file%.csr}.key" -in "${req_file%.csr}.crt" -out "${req_file%.csr}.p12"
	read -p "Supprimer les fichiers locaux de cette certification ? [y/n] "
	[ "${REPLY::1}" = "y" ] && rm -f "${req_file%.csr}."*
fi

echo cp "${req_file%.csr}."* /home/cert/
