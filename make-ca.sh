#!/bin/sh

. ./lib.sh

# lister les crt dont :

#NOM=slct $(
	for cert in $(ls -1 certs/*.crt) ; do
		i=0
	# on a une clef, c'est la bonne
		if [ -f ${cert%.crt}.key ] ; then
			[ "$( s crt "$cert" )" = "$( s key "${cert%.crt}.key" )" ] && let i++
		fi
	# on le droit de signer
		[ $( can_sign "$cert" ) -eq 1 ] && let i++
	# pas déjà été promu signataire
		[ ! -d "ca/${cert%.crt}-ca" ] && let i++
	# est valable
		[ $( is_valid "$cert" ) ] && let i++
		[ $i -eq 4 ] && echo "$cert"
	done
)

if [ -z "$NOM" ] ; then
	echo "aucun certificat sélectionné"
	exit 1
fi

# calcul des noms des différents éléments de la future CA
NOM=${cert%.crt}

d_ca=ca/
d_cadb=ca/$NOM-ca/db/
d_pkey=ca/$NOM-ca/private/
f_cert=
f_pkey=
f_bundle=
f_crl=
f_cfg=
f_db=ca/$NOM-ca/db/$NOM-ca.db
f_attr=ca/$NOM-ca/db/$NOM-ca.db.attr
f_srl_crt=
f_srl_crl=


# création de la structure de la nouvelle CA
mkdir -p "$d_cadb"
mkdir -p -m 700 "$d_pkey"


# déplacer les fichier de l'identifier à promouvoir
mv "certs/$NOM.key" "$d_pkey"
mv "certs/$NOM.*" "$d_ca"


# créer les éléments d'une CA
cp /dev/null "$f_db"
cp /dev/null "$f_attr"
echo 01 > "$f_srl_crt"
echo 01 > "$f_srl_crl"


# générer la chaine
# oulala
# trouver la CA qui a signé le cert qu'on veut promouvoir
# ajouter le crt dans le bundle
# si selfsign, break
# sinon prendre le cert ajouté et [recursion]
cat "ca/$NOM-ca.crt" "ca/nc-root-ca.crt" > "ca/$NOM-ca-chain.pem"


# générer une configuration


# générer une crl
openssl ca -gencrl -config etc/$NOM-ca.conf -out ca/$NOM-ca/$NOM-ca.crl
