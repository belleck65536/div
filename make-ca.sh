#!/bin/sh

if [ -f "./lib.sh" ] ; then
	. ./lib.sh
else
	echo "lib.sh introuvable, démarrage impossible"
	exit 1
fi


# lister les crt dont :
NOM=slct $(
	for cert in $(ls -1 "$dir_crt"/*.crt) ; do
		clef="$dir_key/$( basename "${cert%.crt}.key" )"
		i=0
		let i+=$( match "$cert" "$clef" )
		let i+=$( can_sign "$cert" )
		let i+=$( is_valid "$cert" )
		# pas déjà été promu signataire
		[ ! -d "$dir_ca/${cert%.crt}" ] && let i++
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
cat "$dir_ca/$NOM.crt" "$dir_ca/nc-root-ca.crt" > "$dir_ca/$NOM-ca-chain.pem"


# générer une configuration


# générer une crl
openssl ca -gencrl -config etc/$NOM.conf -out $dir_crl/$NOM.crl
