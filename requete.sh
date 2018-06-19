#!/bin/sh
# permet la creation d'une requete de certificat puis signe le certificat
#
# WORKDIR NOMFIC REQCFG MODREQ
# "${1:-/dev/stdin}" --> prend $1 si stdin est vide

. ./select.sh

WORKDIR=certs/
ec="Courbe eliptique"
rsa="Paire RSA"

while [ "$NOMFIC" = "" ]; do
	read -p "Nom de fichier pour la requête (l'extension sera ajoutée automatiquement) : " NOMFIC
	if [ -f "$WORKDIR$NOMFIC.csr" -o -f "$WORKDIR$NOMFIC.key" ]; then
		echo "nom de requête déjà utilisé"
		NOMFIC=""
	fi;
done

echo "Type de clef ?"
clef=$( slct "$ec" "$rsa" )

case "$clef" in 
	"$ec")
		echo "Type de courbe :"
		keyargs=$( slct secp521r1 secp384r1 prime256v1 )
		[ -n "$keyargs" ] && keyargs="ecparam -genkey -noout -name $keyargs" || exit
	;;
	"$rsa")
		echo "Longueur de clef :"
		keyargs=$( slct 1024 2048 4096 8192 )
		[ -n "$keyargs" ] && keyargs="genrsa $keyargs" || exit
	;;
	*) exit ;;
esac

echo "Modèle de requête :"
cfg_file=$( slct $( ls ./etc/req*.conf ) )

# recherche des extensions disponibles
ext="$( slct $( grep -e "\[.*_ext\s*\]" "$cfg_file" | sed -r 's/\[\s*//g' | sed -r 's/_ext\s*\]//g' | tr '\n' ' ') )_ext"
[ -z "$ext" ] && exit

# ajout d'subjectAltName suivant l'extension demandée
if [ $(echo "$ext" | grep -ic "san" ) -ge 1 ] ; then
	printf "%s\n" "Définition du SAN suivant la forme <type>:<valeur>,<type>:<valeur>,..."
	printf "%s\n" "éléments :\n\tDNS\n\tIP\n\tURI\n\temail\n\tRID\n\tdirName\n\totherName"
	printf "%s\n" "ex : DNS:www.example.com,IP:0.0.0.0"
	while [ -z "$SANC" ]; do
		read SANC
		case $SANC in
			"") echo "???" ;;
			*)	read -p "Appuyez sur une touche pour continuer" d
				SANC="SAN=$SANC"
				;;
		esac
	done
fi
	
openssl $keyargs -out "$WORKDIR$NOMFIC.key"
$SANC openssl req -new -config "etc/$cfg_file" -reqexts $ext -out "$WORKDIR$NOMFIC.csr" -key "$WORKDIR$NOMFIC.key"
# ./signat.sh $REQCFG "$WORKDIR$NOMFIC.csr"
