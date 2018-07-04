#!/bin/sh
#set CA SERNUM RAISON

echo "
S�lection de l'autorit� r�gissant le certificat � r�voquer :
1. Autorit� Racine
2. Autorit� SSL/TLS
3. Autorit� Software
4. Autorit� Email
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
Num�ro de s�rie du certificat ?
"
while true; do
	read SERNUM
	if [ -f "ca/nc-$CA-ca/$SERNUM.pem" ]; then
		break;
	else
		echo "Num�ro de s�rie introuvable sous ca/nc-$CA-ca";
	fi
done

echo "
Raison de la r�vocation ?
1. Non sp�cifi�
2. Certificat compromis
3. Autorit� de certification compromise
4. Modification de l.affiliation
5. Certificat remplac�
6. Cessation d.activit�
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

read -p "S�r ? [y/n] "
if [ "${REPLY::1}" = "y" ]; then
	openssl ca -config "etc/nc-$CA-ca.conf" -revoke "ca/nc-$CA-ca/$SERNUM.pem" -crl_reason $RAISON;
	openssl ca -gencrl -config "etc/nc-$CA-ca.conf" -out "crl/nc-$CA-ca.crl" 2>/dev/null
	# scp -B /mnt/sda1/pki/crl/*.crl 10.0.1.35:/var/www/html/pki/>/dev/null
	/mnt/sda1/pki/updatecrl.sh
fi
