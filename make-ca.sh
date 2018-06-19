#!/bin/sh

# obtention du nom du certificat à promouvoir
while [ -z "$NOM" ]; do
	echo "quel est le nom de l'identité à promouvoir ?"
	read NOM
done


# vérifier présence cert/clef
if [ ! -f "$NOM.crt" -o ! -f "$NOM.key" ] ; then
	echo "fichiers introuvables"
	exit 1
fi


# vérifier cohérence cert/clef


# vérifier si le cert a le droit de signer
a=`openssl x509 -in certs/$NOM.crt  -noout -text | grep -ic "Certificate Sign"`
b=`openssl x509 -in certs/$NOM.crt  -noout -text | grep -ic "CRL Sign"`
c=`openssl x509 -in certs/$NOM.crt  -noout -text | grep -ic "CA:TRUE"`
let "s = a + b + c"

if [ $s -ne 3 ] ; then
	echo "ce certificat ne peut pas porter le rôle d'autorité émettrice"
	exit 2
fi


# création de la structure de la nouvelle CA
mkdir -p "ca/$NOM-ca/db"
mkdir -p -m 700 "ca/$NOM-ca/private"


# déplacer les fichier de l'identifier à promouvoir
mv "certs/$NOM.key" "ca/$NOM-ca/private/"
mv "certs/$NOM.*" "ca/"


# créer les éléments d'une CA
cp /dev/null ca/$NOM-ca/db/$NOM-ca.db
cp /dev/null ca/$NOM-ca/db/$NOM-ca.db.attr
echo 01 > ca/$NOM-ca/db/$NOM-ca.crt.srl
echo 01 > ca/$NOM-ca/db/$NOM-ca.crl.srl


# générer la chaine
cat ca/$NOM-ca.crt ca/nc-root-ca.crt > ca/$NOM-ca-chain.pem


# générer une configuration


# générer une crl
openssl ca -gencrl -config etc/$NOM-ca.conf -out crl/$NOM-ca.crl
