#!/bin/sh
cd "$(dirname "$0")"
if [ -f "./lib.sh" ] ; then
	. "./lib.sh"
else
	echo "lib.sh introuvable, démarrage impossible"
	exit 1
fi


# lister les crt dont :
NOM=slct $(
	for cert in $(ls -1d "$dir_crt"/*.crt) ; do
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

[ -z "$NOM" ] && die 1 "aucun certificat sélectionné"


# calcul des noms des différents éléments de la future CA
NOM="$( basename "${NOM%.crt}" )"


# création de la structure de la nouvelle CA
mkdir -p "$dir_ca/$NOM/db"
mkdir -p -m 700 "$dir_ca/$NOM/private"


# déplacer les fichier de l'identifier à promouvoir
mv "$dir_key/$NOM.key" "$dir_ca/$NOM/private"
mv "$dir_crt/$NOM.crt" "$dir_ca/$NOM"


# créer les éléments d'une CA
cp /dev/null "$dir_ca/$NOM/db/$NOM.db"
cp /dev/null "$dir_ca/$NOM/db/$NOM.db.attr"
echo 01 > "$dir_ca/$NOM/db/$NOM.crt.srl"
echo 01 > "$dir_ca/$NOM/db/$NOM.crl.srl"


# générer la chaine
# RFC-5246 7.4.2
# 1) le cert final, 2) la CA qui a signé [1], 3) la racine qui a signé [2]
#
# oulala
# trouver la CA qui a signé le cert qu'on veut promouvoir
# ajouter le crt dans le bundle
# si selfsign, break
# sinon prendre le cert ajouté et [recursion]
#cat "$dir_ca/$NOM.crt" "$dir_ca/nc-root-ca.crt" > "$dir_ca/$NOM-ca-chain.pem"


# générer une configuration


# générer une crl
#openssl ca -gencrl -config etc/$NOM.conf -out $dir_crl/$NOM.crl
