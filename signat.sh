#!/bin/sh

if [ -f "./lib.sh" ] ; then
	. ./lib.sh
else
	echo "lib.sh introuvable, démarrage impossible"
	exit 1
fi


function display_help () {
	die "Usage : $(basename $0) <configuration> <extensions> <requete>"
}


while getopts ":c:e:i:" opt; do
	case $opt in
		c) [ -f "$OPTARG" ] && cfg_file="$OPTARG" || die "erreur sur fichier de configuration \"$OPTARG\"" ;;
		i) [ -f "$OPTARG" ] && req_file="$OPTARG" || die "erreur sur fichier de requête \"$OPTARG\"" ;;
		e) exten="$OPTARG" ;;
		\?) echo "Invalid option: -$OPTARG" ; display_help ;;
		:) echo "Option -$OPTARG requires an argument." ; display_help ;;
	esac
done


# validation i - si pas d'arg, select CSR
[ -z "$req_file" ] && req_file= $( slct $(
	for csr in $( ls -1 $dir_req/*.csr 2>/dev/null ) ; do
		crt_file=$( basename "${csr%.csr}.crt" )
		[ ! -f "$dir_crt/$crt_file" ] && echo "$csr"
	done
))
[ -z "$req_file" ] && die "aucune requête disponible pour être signée"
[ -f "${req_file%.csr}.crt" ] && die "Nom de certificat signé déjà utilisé \"${req_file%.csr}.crt\""


# validation c - si pas d'arg, select conf
[ -z "$cfg_file" ] && cfg_file=$( slct $( ls -1 $dir_cfg/*.conf 2>/dev/null ) )
[ -z "$cfg_file" ] && die "aucune configuration disponible pour signer la requête"


# validation e - si pas d'arg, select extension "*$ext_ca"
[ -z "$exten" ] && exten="$( slct $( grep -e "\s*\[.*$ext_ca\s*\]\s*" "$cfg_file" | sed -r 's/\s*\[\s*//g' | sed -r 's/\s*\]\s*//g' | tr '\n' ' ') )"
[ -z "$exten" ] && die "aucune extension disponible pour signer la requête"
[ $( grep -c -e "\s*\[\s*$exten\s*\]\s*" "$cfg_file" ) -ne 1 ] && die "anomalie sur extension \"$exten\" dans la configuration \"$cfg_file\""


openssl ca -config "$cfg_file" -in "$req_file" -out "${req_file%.csr}.crt" -extensions "$exten" -notext
