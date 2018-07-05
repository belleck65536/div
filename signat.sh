#!/bin/sh
cd "$(dirname "$0")"
if [ -f "./lib.sh" ] ; then
	. "./lib.sh"
else
	echo "lib.sh introuvable, démarrage impossible"
	exit 1
fi


while getopts ":c:e:i:" opt; do
	case $opt in
		c) [ -f "$OPTARG" ] && cfg_file="$OPTARG" || die 2 "erreur sur fichier de configuration \"$OPTARG\"" ;;
		i) [ -f "$OPTARG" ] && req_file="$OPTARG" || die 2 "erreur sur fichier de requête \"$OPTARG\"" ;;
		e) exten="$OPTARG" ;;
		\?) die 1 "Invalid option: -$OPTARG" ;;
		:)  die 1 "Option -$OPTARG requires an argument." ;;
	esac
done


# validation i - si pas d'arg, select CSR
[ -z "$req_file" ] && req_file=$( slct $(
	for csr in $( ls -1d "$dir_req"/*.csr 2>/dev/null ) ; do
		crt_file="$dir_crt/$( basename "${csr%.csr}.crt" )"
		[ ! -f "$crt_file" ] && echo "$csr"
	done
))
[ -z "$req_file" ] && die 3 "aucune requête disponible pour être signée"
crt_file="$dir_crt/$( basename "${req_file%.csr}.crt" )"
[ -f "$crt_file" ] && die 3 "Nom de certificat signé déjà utilisé \"$crt_file\""


# validation c - si pas d'arg, select conf
[ -z "$cfg_file" ] && cfg_file=$( slct $( ls -1d "$dir_cfg"/*.conf 2>/dev/null ) )
[ -z "$cfg_file" ] && die 4 "aucune configuration disponible pour signer la requête"


# validation e - si pas d'arg, select extension "*$ext_ca"
[ -z "$exten" ] && exten="$( slct $( seek_ext "$ext_ca" "$cfg_file" ) )"
[ -z "$exten" ] && die 5 "aucune extension disponible pour signer la requête"
[ $( grep -c -e "\s*\[\s*$exten\s*\]\s*" "$cfg_file" ) -ne 1 ] && die 5 "anomalie sur extension \"$exten\" dans la configuration \"$cfg_file\""


openssl ca -config "$cfg_file" -in "$req_file" -out "$crt_file" -extensions "$exten" -notext
