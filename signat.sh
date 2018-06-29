#!/bin/sh
#
# signat.sh -c "config_file" -e "extension" -i "req_file"

. ./lib.sh

function display_help () {
	echo "Usage : $(basename $0) <configuration> <extensions> <requete>"
	exit
}

while getopts ":c:e:i:" opt; do
	case $opt in
		c)
			if [ -f "$OPTARG" ] ; then
				cfg_file="$OPTARG"
			else
				echo "erreur sur fichier de configuration \"$OPTARG\""
				exit 1
			fi
		;;
		i)
			if [ -f "$OPTARG" ] ; then
				req_file="$OPTARG"
			else
				echo "erreur sur fichier de requête \"$OPTARG\""
				exit 1
			fi
		;;
		e) exten="$OPTARG" ;;
		\?) echo "Invalid option: -$OPTARG" ; display_help ;;
		:) echo "Option -$OPTARG requires an argument." ; display_help ;;
	esac
done

# validation i
# si pas d'argument fourni, on recherche une CSR
if [ -z "$req_file" ] ; then
	slct  $(
		for csr in $( ls -1 ${dir_req}/*.csr 2>/dev/null ) ; do
			crt_file=$( basename "${csr%.csr}.crt" )
			[ ! -f "$dir_crt/$crt_file" ] && echo "$csr"
		done
	)
fi
# si on a toujours pas d'arguments, c'est qu'il n'y avait rien en entrée et que la sélection n'a rien donné (pas de résultat/tout est signé)
if [ -z "$req_file" ] ; then
	echo "aucune requête disponible pour être signée"
	exit 1
fi

# si le CRT associé existe, on sort car cette vérif a été exécuté lors de la selection des requêtes.
# ce test ne sert que pour l'utilsation avec arguments
if [ -f "${req_file%.csr}.crt" ] ; then
	echo "Nom de certificat signé déjà utilisé \"${req_file%.csr}.crt\""
	exit 1
fi

# validation c
[ -z "$cfg_file" ] && slct $( ls *-ca/*.conf 2>/dev/null )
# choisir config, si liste vide, sortir
if [ -z "$cfg_file" ] ; then
	echo "aucune configuration disponible pour signer la requête"
	exit 1
fi

# validation e
if [ -z "$exten" ] ; then
	exten="$( slct $( grep -e "\s*\[.*_ca\s*\]\s*" "$cfg_file" | sed -r 's/\s*\[\s*//g' | sed -r 's/\s*\]\s*//g' | tr '\n' ' ') )_ca"
fi
if [ -z "$exten" ] ; then
	echo "aucune extension disponible pour signer la requête"
	exit 1
fi
if [ $( grep -ec "\s*\[\s*$exten\s*\]\s*" ) -lt 1 ] ; then
	echo "extension \"$exten\" introuvable dans la configuration \"$cfg_file\""
	exit 1
fi

echo openssl ca -config "$cfg_file" -in "$req_file" -out "${req_file%.csr}.crt" -extensions "$exten" -notext

if [ -f "${req_file%.csr}.key" -a -f "${req_file%.csr}.crt" ]; then
	read -p "Convertir le certificat signé en PKCS#12 ? [y/n] " R
	[ "${R::1}" = "y" ] && openssl pkcs12 -export -inkey "${req_file%.csr}.key" -in "${req_file%.csr}.crt" -out "${req_file%.csr}.p12"
	read -p "Supprimer les fichiers locaux de cette certification ? [y/n] " R
	[ "${R::1}" = "y" ] && rm -f "${req_file%.csr}."*
fi

echo cp "${req_file%.csr}."* /home/cert/
