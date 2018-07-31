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
		c) [ -f "$optarg" ] && cfg_file="$optarg" || die 2 "erreur sur fichier de configuration \"$optarg\"" ;;
		i) [ -f "$optarg" ] && req_file="$optarg" || die 2 "erreur sur fichier de requête \"$optarg\"" ;;
		e) exten="$optarg" ;;
		\?) die 1 "Invalid option: -$optarg" ;;
		:)  die 1 "Option -$optarg requires an argument." ;;
	esac
done


# validation i - si pas d'arg, select CSR
[ -z "$req_file" ] && req_file=$( slct $(
	for csr in $( ls -1d "$dir_req/*.csr" 2>/dev/null ) ; do
		e=0
		[ -f "$dir_crt/$( basename "${csr%.csr}.crt" )" ] && let e++
		[ -d "$dir_ca/$( basename "${csr%.csr}" )" ] && let i++
		[ $e -eq 0 ] && echo "$csr"
	done
))
[ -z "$req_file" ] && die 3 "aucune requête disponible pour être signée"
crt_file="$dir_crt/$( basename "${req_file%.csr}.crt" )"
# vérifier présence crt promu CA
[ -f "$crt_file" ] && die 3 "Nom de certificat signé déjà utilisé \"$crt_file\""


# validation c - si pas d'arg, select conf
[ -z "$cfg_file" ] && cfg_file=$( slct $( ls -1d "$dir_ca/*.conf" 2>/dev/null ) )
[ -z "$cfg_file" ] && die 4 "aucune configuration disponible pour signer la requête"
base="${cfg_file%.conf}"
[ ! -d "$base" ] && die 5 "anomalie lors de l'accès au dossier de la CA demandée"

# vérifier la validité temporelle de la CA associée à la conf (intégrer au slct du dessus ?)

# validation e - si pas d'arg, select extension "*$ext_ca"
[ -z "$exten" ] && exten="$( slct $( seek_ext "$ext_ca" "$cfg_file" ) )"
[ -z "$exten" ] && die 6 "aucune extension disponible pour signer la requête"
[ $( grep -c -e "\s*\[\s*$exten\s*\]\s*" "$cfg_file" ) -ne 1 ] && die 5 "anomalie sur extension \"$exten\" dans la configuration \"$cfg_file\""


SAN=_ openssl ca -config "$cfg_file" -extensions "$exten" -in "$req_file" -out "$crt_file" -notext
cat "$crt_file" "$dir_ca/$base-chain.pem" > "${crt_file%.crt}-chain.pem"

