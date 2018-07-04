#!/bin/sh

if [ -f "$(dirname "$0")/lib.sh" ] ; then
	. "$(dirname "$0")/lib.sh"
else
	echo "lib.sh introuvable, démarrage impossible"
	exit 1
fi


while [ -z "$nom" ]; do
	read -p "Nom de fichier pour la requête (l'extension sera ajoutée automatiquement) : " nom
	if [ -f "$dir_req/$nom.csr" -o -f "$dir_key/$nom.key" ]; then
		echo "nom de requête déjà utilisé"
		nom=""
	fi;
done


echo "Type de clef ?" ; CLEF=$( slct "$EC" "$RSA" )
case "$CLEF" in 
	"$EC")
		echo "Type de courbe :" ; KEYARGS=$( slct $(curve_list) )
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
EXT=$( slct $( seek_ext "$ext_req" "$CFG_FILE" ) )
[ -z "$EXT" ] && die 2 "aucune extension trouvée dans ce fichier de configuration"


# ajout d'subjectAltName suivant l'extension demandée
# si mention "san" absente, alors on demande le SAN (logique="without san")
if [ $(echo "$EXT" | grep -ic "san") -eq 0 ] ; then
	printf "%s\n" "Définition du SAN suivant la forme <type>:<valeur>,<type>:<valeur>,..."
	printf "Eléments :\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n" DNS IP URI email RID dirName otherName
	printf "%s\n" "ex : DNS:www.example.com,IP:0.0.0.0"
	while [ -z "$SANC" ]; do
		read SANC
	done
else
	SANC="_"
fi


read -p "autosignature de la requête ? (ex : certificat racine / test) [y|N] : " ASask
case "$ASask" in
	y|Y|o|O) AS="-x509 -extensions" ; fe=crt ;;
	n|N|*) AS="-reqexts" ; fe=csr ;;
esac


openssl $KEYARGS >> "$dir_key/$nom.key"
SAN=$SANC openssl req -new -config "$CFG_FILE" $AS "$EXT" -out "$dir_req/$nom.$fe" -key "$dir_key/$nom.key"
# ./signat.sh -i "$dir_req/$nom.csr"
