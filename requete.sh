#!/bin/sh
#
# "${1:-/dev/stdin}" --> prend $1 si stdin est vide

. ./select.sh

WORKDIR=certs/
EC="Courbe eliptique"
RSA="Paire RSA"

while [ "$NOMFIC" = "" ]; do
	read -p "Nom de fichier pour la requête (l'extension sera ajoutée automatiquement) : " NOMFIC
	if [ -f "$WORKDIR$NOMFIC.csr" -o -f "$WORKDIR$NOMFIC.key" ]; then
		echo "nom de requête déjà utilisé"
		NOMFIC=""
	fi;
done

echo "Type de clef ?"
CLEF=$( slct "$EC" "$RSA" )

case "$CLEF" in 
	"$EC")
		echo "Type de courbe :"
		KEYARGS=$( slct secp521r1 secp384r1 prime256v1 )
		[ -n "$KEYARGS" ] && KEYARGS="ecparam -genkey -noout -name $KEYARGS" || exit
	;;
	"$RSA")
		echo "Longueur de clef :"
		KEYARGS=$( slct 1024 2048 4096 8192 )
		[ -n "$KEYARGS" ] && KEYARGS="genrsa $KEYARGS" || exit
	;;
	*) exit ;;
esac

echo "Modèle de requête :"
CFG_FILE=$( slct $( ls ./etc/req*.conf ) )

# recherche des extensions disponibles
EXT="$( slct $( grep -e "\[.*_ext\s*\]" "$CFG_FILE" | sed -r 's/\[\s*//g' | sed -r 's/_ext\s*\]//g' | tr '\n' ' ') )_ext"
[ -z "$EXT" ] && exit

# ajout d'subjectAltName suivant l'extension demandée
if [ $(echo "$EXT" | grep -ic "san" ) -ge 1 ] ; then
	printf "%s\n" "Définition du SAN suivant la forme <type>:<valeur>,<type>:<valeur>,..."
	printf "%s\n" "éléments :\n\tDNS\n\tIP\n\tURI\n\temail\n\tRID\n\tdirName\n\totherName"
	printf "%s\n" "ex : DNS:www.example.com,IP:0.0.0.0"
	while [ -z "$SANC" ]; do
		read SANC
		case $SANC in
			"") echo "???" ;;
			*)	read -p "Appuyez sur une touche pour continuer" D
				SANC="SAN=$SANC"
				;;
		esac
	done
else
	SANC="SAN=#"
fi
	
openssl $KEYARGS -out "$WORKDIR$NOMFIC.key"
$SANC openssl req -new -config "$CFG_FILE" -reqexts $EXT -out "$WORKDIR$NOMFIC.csr" -key "$WORKDIR$NOMFIC.key"
# ./signat.sh $CFG_FILE "$WORKDIR$NOMFIC.csr"
