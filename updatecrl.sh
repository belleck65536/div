#!/bin/sh
# verifier l'expiration des crl, les mettre a jour si necessaire
# et envoi crt + crl sur websrv

. ./lib.sh

cd $(dirname $0)
#echo `pwd` >> ./pate.log

let NOW=$( date +%s )+86400*1

# pour la CRL de chaque CA
for crl in $(ls -1 "$dir_crl"); do
	# obtention de la date de fin de validité de la CRL
	CRL_END=$( openssl crl -in "$dir_crl/$crl" -nextupdate -noout 2>/dev/null )
	CRL_END=$( openssl_time2epoch ${CRL_END#nextUpdate=} )

	# si mise à jour forcée, on modifie l'expiration de la CRL à la nuit des temps
	if [ "$1" = "-force" ]; then
		echo "$( date ) - mise a jour forcee" >>updt.log
		$CRL_END=0
	fi

	# si la CRL est dépassée, on renouvelle
	if [ $NOW -ge $CRL_END ]; then
		echo "$( date ) - renouvellement necessaire de $crl" >>updt.log
		openssl ca -gencrl -config "$dir_cfg/${crl%.crl}.conf" -out "$crl" 2>/dev/null;
	fi
done

scp -B $dir_crl/*.crl dlboxwkr@dlbox:/var/www/html/pki/>/dev/null
scp -B $dir_ca/*.crt dlboxwkr@dlbox:/var/www/html/pki/>/dev/null

