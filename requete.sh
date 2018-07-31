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
	[ -f "$dir_crt/$nom-chain.pem" ] && let e++
	[ -d "$dir_ca/$nom" ] && let e++
	if [ $e -gt 0 ] ; then
		echo "nom de requête déjà utilisé"
		nom=""
	fi;
done


echo "Type de clef ?" ; clef=$( slct "$EC" "$RSA" )
case "$clef" in 
	"$EC")
		echo "Type de courbe :" ; keyargs=$( slct $(curve_list) )
		[ -n "$keyargs" ] && keyargs="ecparam -genkey -noout -name $keyargs" || exit
	;;
	"$RSA")
		echo "Longueur de clef :" ; keyargs=$( slct 2048 4096 8192 )
		[ -n "$keyargs" ] && keyargs="genrsa $keyargs" || exit
	;;
	*) exit ;;
esac


# la CA signataire ajoute les extensions
# l'important c'est avec ou sans SAN
# pour une selfsign, les extensions doivent être fournies
# on ne fera de l'auto sign que pour une rootCA
echo "Modèle de requête :"
cfg_file=$( slct $( ls -1d "$dir_cfg/*.conf" ) )
[ -z "$cfg_file" ] && die 1 "aucun fichier de configuration disponible"


# recherche des extensions disponibles
ext=$( slct $( seek_ext "$ext_req" "$cfg_file" ) )
[ -z "$ext" ] && die 2 "aucune extension trouvée dans ce fichier de configuration"


# ajout d'subjectAltName suivant l'extension demandée
if [ $(echo "$ext" | grep -ic "no_san") -eq 0 ] ; then
	printf "%s\n" "Définition du SAN suivant la forme <type>:<valeur>,<type>:<valeur>,..."
	printf "Eléments :\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n" DNS IP URI email RID dirName otherName
	printf "%s\n" "ex : DNS:www.example.com,IP:0.0.0.0"
	while [ -z "$sanc" ]; do
		read sanc
	done
else
	sanc="_"
fi


read -p "autosignature de la requête ? (ex : certificat racine / test) [y/N] : " ASask
case "$ASask" in
	y|Y|o|O) AS=1 ;;
	*) AS=0 ;;
esac
if [ "$AS" = "1" ] ; then
	reqarg="-x509 -extensions"
	crt_file="$dir_crt/$nom.crt"
else
	reqarg="-reqexts"
	crt_file="$dir_req/$nom.csr"
fi


openssl $keyargs >> "$dir_key/$nom.key"
SAN=$sanc openssl req -new -config "$cfg_file" $reqarg "$ext" -key "$dir_key/$nom.key" -out "$crt_file"

case "$AS" in
	0)
		read -p "Lancer signature ? [y/N]" R
		[ "${R::1}" = "y" ] && ./signat.sh -i "$crt_file"
	;;
	1)
		read -p "Promotion en CA de la demande autosignée ? [y/N]" R
		if [ "${R::1}" = "y" ] ;then
			cp -a "$crt_file" "${crt_file%.crt}-chain.pem"
			./make-ca.sh -i "$crt_file"
		fi
	;;
esac
