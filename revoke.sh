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
	for authority in $( ls -1 "$dir_ca" 2>/dev/null | egrep "\.crt$" ) ; do
		auth="${authority%.crt}"
		[ -d "$auth" ] && echo "$(basename "$auth")"
	done
))
[ -z "$ca" ] && exit


echo "Numéro de série du certificat ? "
crt_sn=$( slct $(
	# obtenir une liste des certificats signés dans le dossier de la CA
	for crt in $( ls -1 "$dir_ca/$ca" 2>/dev/null | egrep "\.pem$" ) ; do
		sn="${crt%.pem}"
		li=$( grep -i -E "[RVE]$tab[0-9]{12}Z$tab[^$tab]*$tab$sn$tab[^$tab]*$tab[^$tab]*" "$dir_ca/$ca/db/$ca.db" )
		st=$( echo "$li" | cut -f1 )
		ex=$( echo "$li" | cut -f2 )
		# ici on peut avoir un VMETP si date est dans une version qui gère les dates en 32b
		exp=$( date -d "20${ex:0:2}-${ex:2:2}-${ex:4:2} ${ex:6:2}:${ex:8:2}:${ex:10:2}" +%s )
		# remonter les cert encore valides et NON marqués révoqué/expirés dans la db de la CA
		[ "$st" = "V" -a "$exp" -ge "$NOW" ] 2>/dev/null && echo "$sn"
	done
))
[ -z "$crt_sn" ] && exit


openssl x509 -in "$dir_ca/$ca/$crt_sn.pem" -noout -issuer -serial -subject -nameopt RFC2253


echo "Raison de la révocation ? "
raison=$( slct unspecified keyCompromise CACompromise affiliationChanged superseded cessationOfOperation )
[ -z "$raison" ] && exit


read -p "Sûr ? [y/N] " R
if [ "${R::1}" = "y" ]; then
	openssl ca -config "$dir_ca/$ca.conf" -revoke "$dir_ca/$ca/$crt_sn.pem" -crl_reason $raison
	./crl.sh force "$dir_ca/$ca.conf"
fi
