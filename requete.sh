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
CFG_FILE="$dir_cfg/$( slct $( ls -1 $dir_cfg ) )"
[ -z "$CFG_FILE" ] && die "aucun fichier de configuration disponible"


# recherche des extensions disponibles
EXT="$( slct $( grep -e "\[.*_ext\s*\]" "$CFG_FILE" | sed -r 's/\[\s*//g' | sed -r 's/_ext\s*\]//g' | tr '\n' ' ') )_ext"
[ -z "$EXT" ] && die "aucune extension trouvée dans ce fichier de configuration"


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
	SANC="#"
fi


read -p "autosignature de la requête ? (ex : certificat racine / test) : " AS
case "$AS" in
	y|Y|o|O) AS=" -x509";;
	n|N|*) AS="";;
esac


openssl $KEYARGS >> "$dir_key/$NOM.key"
SAN=$SANC openssl req -new -config "$CFG_FILE" -reqexts $EXT -out "$dir_req/$NOM.csr" -key "$dir_key/$NOM.key" -x509
# ./signat.sh $CFG_FILE "$dir_req/$NOM.csr"
