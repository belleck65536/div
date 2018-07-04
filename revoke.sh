#!/bin/sh
cd "$(dirname "$0")"
if [ -f "./lib.sh" ] ; then
	. "./lib.sh"
else
	echo "lib.sh introuvable, démarrage impossible"
	exit 1
fi


echo "
Sélection de l'autorité régissant le certificat à révoquer :
1. Autorité Racine
2. Autorité SSL/TLS
3. Autorité Software
4. Autorité Email
"
while [ "$CA" = "" ]; do
	read
	case $REPLY in
		1) CA=root;;
		2) CA=tls;;
		3) CA=software;;
		4) CA=email;;
		*) echo "Choix incorrect";;
	esac
done

echo "
Numéro de série du certificat ?
"
while true; do
	read SERNUM
	if [ -f "ca/nc-$CA-ca/$SERNUM.pem" ]; then
		break;
	else
		echo "Numéro de série introuvable sous ca/nc-$CA-ca";
	fi
done

echo "
Raison de la révocation ?
1. Non spécifié
2. Certificat compromis
3. Autorité de certification compromise
4. Modification de l.affiliation
5. Certificat remplacé
6. Cessation d.activité
"
while [ "$RAISON" = "" ]
do
	read
	case $REPLY in
		1) RAISON=unspecified;;
		2) RAISON=keyCompromise;;
		3) RAISON=CACompromise;;
		4) RAISON=affiliationChanged;;
		5) RAISON=superseded;;
		6) RAISON=cessationOfOperation;;
		*) echo "Choix incorrect";;
	esac
done

openssl x509 -in "ca/nc-$CA-ca/$SERNUM.pem" -noout -issuer -serial -subject -nameopt RFC2253

read -p "Sûr ? [y/n] "
if [ "${REPLY::1}" = "y" ]; then
	openssl ca -config "etc/nc-$CA-ca.conf" -revoke "ca/nc-$CA-ca/$SERNUM.pem" -crl_reason $RAISON;
	openssl ca -gencrl -config "etc/nc-$CA-ca.conf" -out "crl/nc-$CA-ca.crl" 2>/dev/null
	# scp -B /mnt/sda1/pki/crl/*.crl 0.0.0.0:/var/www/html/pki/>/dev/null
	/mnt/sda1/pki/updatecrl.sh
fi
