#!/bin/sh
# permet la creation d'une requete de certificat puis signe le certificat
#
# WORKDIR NOMFIC REQCFG MODREQ
# "${1:-/dev/stdin}" --> prend $1 si stdin est vide

. ./select.sh

WORKDIR=certs/

while [ "$NOMFIC" = "" ]; do
	read -p "Nom de fichier pour la requête (l'extension sera ajoutée automatiquement) : " NOMFIC
	if [ -f "$WORKDIR$NOMFIC.csr" -o -f "$WORKDIR$NOMFIC.key" ]; then
		echo "nom de requête déjà utilisé"
		NOMFIC=""
	fi;
done


ec="Courbe eliptique"
rsa="Paire RSA"

echo "Type de clef ?"
clef=$( slct "$ec" "$rsa" )

if [ "$clef" -eq "$ec" ] ; then
	echo "Type de courbe :"
	keyargs="ecparam -genkey -noout -name $( slct secp521r1 secp384r1 prime256v1 )"
fi

if [ "$clef" -eq "$rsa" ] ; then
	echo "Longueur de clef :"
	keyopt="genrsa $( slct 1024 2048 4096 8192 )"
fi


echo "Modèle de requête :
cfg_file=$( slct $( ls ./etc/req*.conf ) )

# recherche des extensions disponibles
ext="$( slct $( grep -e "\[.*_ext\s*\]" "$cfg_file" | sed -r 's/\[\s*//g' | sed -r 's/_ext\s*\]//g' | tr '\n' ' ') )_ext"

if [ "${ext//san/}" != "$ext" ] ; then
	# contient "san", donc il faut afficher l'édition du SAN
	echo "Définition du SAN
	élements : DNS | IP | URI | email | RID | dirName | otherNmae
	ex : DNS:www.example.com,IP:0.0.0.0"
	while [ -z "$SANC" ]; do
		read SANC
		case $SANC in
			"") echo "???" ;;
			*) read -p "Appuyez sur une touche pour continuer" dummy ;;
		esac
	done
fi

	
openssl $keyargs -out "$WORKDIR$NOMFIC.key"
# SAN=$SANC openssl req -new -config "etc/$cfg_file" -reqexts $ext -out "$WORKDIR$NOMFIC.csr" -key "$WORKDIR$NOMFIC.key"
# ./signat.sh $REQCFG "$WORKDIR$NOMFIC.csr"
