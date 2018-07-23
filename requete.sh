#!/bin/sh
cd "$(dirname "$0")"
if [ -f "./lib.sh" ] ; then
	. "./lib.sh"
else
	echo "lib.sh introuvable, démarrage impossible"
	exit 1
fi


while [ -z "$nom" ]; do
	read -p "Nom de fichier pour la requête (l'extension sera ajoutée automatiquement) : " nom
	e=0
	[ -f "$dir_key/$nom.key" ] && let e++
	[ -f "$dir_req/$nom.csr" ] && let e++
	[ -f "$dir_crt/$nom.crt" ] && let e++
	[ -d "$dir_ca/$nom" ] && let e++
	if [ $e -gt 0 ] ; then
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


# la CA signataire ajoute les extensions
# l'important c'est avec ou sans SAN
# pour une selfsign, les extensions doivent être fournies
# on ne fera de l'auto sign que pour une rootCA
echo "Modèle de requête :"
CFG_FILE=$( slct $( ls -1d "$dir_cfg"/*.conf ) )
[ -z "$CFG_FILE" ] && die 1 "aucun fichier de configuration disponible"


# recherche des extensions disponibles
EXT=$( slct $( seek_ext "$ext_req" "$CFG_FILE" ) )
[ -z "$EXT" ] && die 2 "aucune extension trouvée dans ce fichier de configuration"


# ajout d'subjectAltName suivant l'extension demandée
if [ $(echo "$EXT" | grep -ic "no_san") -eq 0 ] ; then
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
	y|Y|o|O) AS=1 ; fe=crt ;;
	n|N|*) AS=0 ; fe=csr ;;
esac

[ "$AS" = "1" ] && reqarg="-x509 -extensions" || reqarg="-reqexts"
[ "$AS" = "1" ] && fe="$dir_crt/$nom.crt" || fe="$dir_req/$nom.csr"

openssl $KEYARGS >> "$dir_key/$nom.key"
SAN=$SANC openssl req -new -config "$CFG_FILE" $reqarg "$EXT" -key "$dir_key/$nom.key" -out "$fe"

case "$AS" in
	0)
		read -p "Lancer signature ? [y/N]" R
		[ "${R::1}" = "y" ] && ./signat.sh -i "$fe"
	;;
	1)
		read -p "Promotion en CA de la demande autosignée ? [y/N]" R
		if [ "${R::1}" = "y" ] ;then
			cp "$fe" "${fe%.crt}-chain.pem"
			./make-ca.sh -i "$fe"
		fi
	;;
esac
