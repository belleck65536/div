#!/bin/sh

. ./lib.sh

while [ "$NOM" = "" ]; do
	read -p "Nom de fichier pour la requête (l'extension sera ajoutée automatiquement) : " NOM
	if [ -f "$dir_req/$NOM.csr" -o -f "$dir_key/$NOM.key" ]; then
		echo "nom de requête déjà utilisé"
		NOM=""
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
CFG_FILE=$( slct $( ls -1 "$dir_cfg/req*.conf" ) )

# recherche des extensions disponibles
EXT="$( slct $( grep -e "\[.*_ext\s*\]" "$CFG_FILE" | sed -r 's/\[\s*//g' | sed -r 's/_ext\s*\]//g' | tr '\n' ' ') )_ext"
[ -z "$EXT" ] && exit

# ajout d'subjectAltName suivant l'extension demandée
# si mention "san" absente, alors on demande le SAN (logique="without san")
if [ $(echo "$EXT" | grep -ic "san") -eq 0 ] ; then
	printf "%s\n" "Définition du SAN suivant la forme <type>:<valeur>,<type>:<valeur>,..."
	printf "%s\n" "éléments :\n\tDNS\n\tIP\n\tURI\n\temail\n\tRID\n\tdirName\n\totherName"
	printf "%s\n" "ex : DNS:www.example.com,IP:0.0.0.0"
	while [ -z "$SANC" ]; do
		read SANC
		case $SANC in
			"") echo "???" ;;
			*)	read -p "Appuyez sur une touche pour continuer" D
				SANC="$SANC"
				;;
		esac
	done
else
	SANC="#"
fi
	
openssl $KEYARGS >> "$dir_key/$NOM.key"
SAN=$SANC openssl req -new -config "$CFG_FILE" -reqexts $EXT -out "$dir_req/$NOM.csr" -key "$dir_key/$NOM.key"
# ./signat.sh $CFG_FILE "$dir_req/$NOM.csr"
