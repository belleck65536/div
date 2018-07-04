#!/bin/sh

if [ -f "./lib.sh" ] ; then
	. ./lib.sh
else
	echo "lib.sh introuvable, démarrage impossible"
	exit 1
fi


while [ "$NOM" = "" ]; do
	read -p "Nom de fichier pour la requête (l'extension sera ajoutée automatiquement) : " NOM
	if [ -f "$dir_req/$NOM.csr" -o -f "$dir_key/$NOM.key" ]; then
		echo "nom de requête déjà utilisé"
		NOM=""
	fi;
done


echo "Type de clef ?" ; CLEF=$( slct "$EC" "$RSA" )
case "$CLEF" in 
	"$EC")
		echo "Type de courbe :" ; KEYARGS=$( slct secp521r1 secp384r1 prime256v1 )
		[ -n "$KEYARGS" ] && KEYARGS="ecparam -genkey -noout -name $KEYARGS" || exit
	;;
	"$RSA")
		echo "Longueur de clef :" ; KEYARGS=$( slct 2048 4096 8192 )
		[ -n "$KEYARGS" ] && KEYARGS="genrsa $KEYARGS" || exit
	;;
	*) exit ;;
esac


echo "Modèle de requête :"
CFG_FILE=$( slct $( ls -1 "$dir_cfg"/* ) )
[ -z "$CFG_FILE" ] && die 1 "aucun fichier de configuration disponible"


# recherche des extensions disponibles
EXT=$( slct $( grep -e "\s*\[.*$ext_req\s*\]\s*" "$CFG_FILE" | sed -r 's/\s*\[\s*//g' | sed -r 's/\s*\]\s*//g' | tr '\n' ' ') )
[ -z "$EXT" ] && die 2 "aucune extension trouvée dans ce fichier de configuration"


# ajout d'subjectAltName suivant l'extension demandée
# si mention "san" absente, alors on demande le SAN (logique="without san")
if [ $(echo "$EXT" | grep -ic "san") -eq 0 ] ; then
	printf "%s\n" "Définition du SAN suivant la forme <type>:<valeur>,<type>:<valeur>,..."
	printf "Eléments :\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n" DNS IP URI email RID dirName otherName
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
	SANC="_"
fi


read -p "autosignature de la requête ? (ex : certificat racine / test) [y|N] : " ASask
case "$ASask" in
	y|Y|o|O) AS="-x509 -extensions" ; fe=crt ;;
	n|N|*) AS="-reqexts" ; fe=csr ;;
esac


openssl $KEYARGS >> "$dir_key/$NOM.key"
SAN=$SANC openssl req -new -config "$CFG_FILE" $AS "$EXT" -out "$dir_req/$NOM.$fe" -key "$dir_key/$NOM.key"
# ./signat.sh -i "$dir_req/$NOM.csr"
