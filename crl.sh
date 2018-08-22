#!/bin/sh
cd "$(dirname "$0")"
if [ -f "./lib.sh" ] ; then
	. "./lib.sh"
else
	echo "lib.sh introuvable, démarrage impossible"
	exit 1
fi


case "$1" in
	force)
		cfg_file="$2"
		[ ! -f "$cfg_file" ] && die 2 "config file not found"
		crl_file="$dir_crl/$( basename "${cfg_file%.conf}.crl" )"
		openssl ca -gencrl -config "$cfg_file" -out "$crl_file" 2>/dev/null
	;;
	update)
		[ "$2" = "-f" ] && force_update=1 || force_update=0	
		for crl in $( ls -1 "$dir_crl" 2>/dev/null | egrep "\.crl$" ); do
			crl_file="$dir_crl/$crl"
			cfg_file="$dir_cfg/$( basename "${crl_file%.crl}.conf" )"

			if [ "$force_update" = "1" ] ; then
				echo "$( date ) - mise à jour forcée" >>"$dir_log/updt.log"
				# si mise à jour forcée, on modifie l'expiration de la CRL à la nuit des temps
				CRL_END=0
			else
				# obtention de la date de fin de validité de la CRL
				CRL_END=$( openssl crl -in "$crl_file" -nextupdate -noout 2>/dev/null )
				CRL_END=$( openssl_time2epoch ${CRL_END#nextUpdate=} )
			fi

			# si la CRL est dépassée, on renouvelle
			if [ $NOW -ge $CRL_END ]; then
				echo "$( date ) - renouvellement de $crl_file" >>"$dir_log/updt.log"
				openssl ca -gencrl -config "$cfg_file" -out "$crl_file" 2>/dev/null
			fi
		done
	;;
	*)
		die 1 "option \"$1\" non reconnue"
	;;
esac


scp -B $dir_crl/*.crl dlboxwkr@dlbox:/var/www/html/pki/>/dev/null
scp -B $dir_ca/*.crt dlboxwkr@dlbox:/var/www/html/pki/>/dev/null
