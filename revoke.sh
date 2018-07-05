#!/bin/sh
cd "$(dirname "$0")"
if [ -f "./lib.sh" ] ; then
	. "./lib.sh"
else
	echo "lib.sh introuvable, démarrage impossible"
	exit 1
fi


echo "Sélection de l'autorité régissant le certificat à révoquer : "
ca=$(slct $(
	for authority in $( ls -1 "$dir_ca"/ 2>/dev/null ) ; do
		[ -d "$authority" ] && echo "$(basename "$authority")"
	done
))
[ -z "$ca" ] && exit


$tab=$( printf "\t" )
echo "Numéro de série du certificat ? "
crt_sn=$( slct $(
	# obtenir une liste des certificats signés dans le dossier de la CA
	for crt in $( ls -1 "$dir_ca/$ca"/*.pem ) ; do
		sn=$( basename "${crt%.pem}" )
		ligne=$( grep -i -e "[RVE]$tab[0-9]{12}Z$tab.*$tab[0-9A-Fa-f]+$tab.*$tab[^$tab]*" "$dir_ca/$ca/db/$ca.db" )
		st=$(  echo "$ligne" | cut -f1 )
		exp=$( echo "$ligne" | cut -f2 )
		# ne  les cert marqués révoqué/expirés dans la db de la CA
		[ "$st" = "V" ] && echo "$sn"
		# ne remonter que les cert encore valides dans la db de la CA
		[ $exp -ge $NOW ] && echo "$sn"
	done
))
[ -z "$crt_sn" ] && exit


echo "Raison de la révocation ? "
raison=$( slct unspecified keyCompromise CACompromise affiliationChanged superseded cessationOfOperation )
[ -z "$raison" ] && exit


openssl x509 -in "$dir_ca/$ca/$crt_sn.pem" -noout -issuer -serial -subject -nameopt RFC2253


read -p "Sûr ? [y/n] "
if [ "${REPLY::1}" = "y" ]; then
	openssl ca -config "$dir_etc/$ca.conf" -revoke "$dir_ca/$ca/$crt_sn.pem" -crl_reason $raison;
#	openssl ca -gencrl -config "etc/nc-$CA-ca.conf" -out "crl/nc-$CA-ca.crl" 2>/dev/null
#	/mnt/sda1/pki/updatecrl.sh
fi
