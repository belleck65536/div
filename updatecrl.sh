#!/bin/sh
# verifier l'expiration des crl, les mettre a jour si necessaire
# et envoi crt + crl sur websrv

. ./lib.sh

cd $(dirname $0)
#echo `pwd` >> ./pate.log

SYSDATEOFF=$(( `date +%s`+86400*1 ))

# pour la CRL de chaque CA
for crl in $(ls -1 "$dir_ca/*/*.crl"); do
	cfg=${crl%.crl}.conf

	# obtention de la date de fin de validité de la CRL
	END=$( openssl crl -in "$crl" -nextupdate -noout 2>/dev/null )
	END=$( openssl_time2epoch ${END#nextUpdate=} )

	if [ "$1" = "-force" ]; then
		echo "$( date ) - mise a jour forcee" >>updt.log
		openssl ca -gencrl -config "$cfg" -out "$crl" 2>/dev/null;
	elif [ $SYSDATEOFF -gt $( date -d "$ANNE-$MOI-$JOUR $HEUR" +%s ) ]; then
		echo "$( date ) - renouvellement necessaire de $crl" >>updt.log
		openssl ca -gencrl -config "$cfg" -out "$crl" 2>/dev/null;
	fi
done

scp -B $dir_ca/*/*.cr? dlboxwkr@dlbox:/var/www/html/pki/>/dev/null
#scp -B $dir_ca/*/*.crt dlboxwkr@dlbox:/var/www/html/pki/>/dev/null

