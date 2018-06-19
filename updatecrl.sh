#!/bin/sh
# verifier l'expiration des crl, les mettre a jour si necessaire
# et envoi crt + crl sur websrv
#
# SYSDATEOFF j k END ENDC MOIS JOUR HEUR ANNE MOI

cd `dirname $0`
#echo `pwd` >> ./pate.log

  SYSDATEOFF=$(( `date +%s`+86400*1 ))
# SYSDATEOFF=$(( `date -d "2014-01-10 08:42:14" +%s`+3600*24 ))

for j in $(ls -1 crl/*.crl); do
	k=`basename $j`
	k=etc/${k%crl}conf
	END=`openssl crl -in "$j"  -nextupdate -noout 2>/dev/null`

	ENDC=${END#nextUpdate=}
	MOIS=$(echo $ENDC | awk '{ print $1 }')
	JOUR=$(echo $ENDC | awk '{ print $2 }')
	HEUR=$(echo $ENDC | awk '{ print $3 }')
	ANNE=$(echo $ENDC | awk '{ print $4 }')
	case $MOIS in
		Jan) MOI=01;;
		Feb) MOI=02;;
		Mar) MOI=03;;
		Apr) MOI=04;;
		May) MOI=05;;
		Jun) MOI=06;;
		Jul) MOI=07;;
		Aug) MOI=08;;
		Sep) MOI=09;;
		Oct) MOI=10;;
		Nov) MOI=11;;
		Dec) MOI=12;;
		*) echo erreur date crl ; break;;
	esac

	if [ "$1" = "-force" ]; then
		echo `date` - mise a jour forcee >>updt.log
		openssl ca -gencrl -config "$k" -out "$j" 2>/dev/null;
	elif [ $SYSDATEOFF -gt `date -d "$ANNE-$MOI-$JOUR $HEUR" +%s` ]; then
		echo `date` - renouvellement necessaire de $j >>updt.log
		openssl ca -gencrl -config "$k" -out "$j" 2>/dev/null;
	fi
done

scp -B /mnt/sda1/pki/crl/*.crl dlboxwkr@dlbox:/var/www/html/pki/>/dev/null
scp -B /mnt/sda1/pki/ca/*.crt  dlboxwkr@dlbox:/var/www/html/pki/>/dev/null

