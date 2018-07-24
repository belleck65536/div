#!/bin/sh
cd "$(dirname "$0")"
if [ -f "./lib.sh" ] ; then
	. "./lib.sh"
else
	echo "lib.sh introuvable, démarrage impossible"
	exit 1
fi


# argument en entrée : -i pour le certificat à promouvoir
while getopts ":i:" opt; do
	case $opt in
		i) [ -f "$OPTARG" ] && crt_file="$OPTARG" || die 2 "erreur sur le certificat à promouvoir \"$OPTARG\"" ;;
		\?) die 3 "Invalid option: -$OPTARG" ;;
		:)  die 2 "Option -$OPTARG requires an argument." ;;
	esac
done


# lister les crt dont :
[ -z "$crt_file" ] && crt_file=$( slct $(
	for cert in $(ls -1d "$dir_crt"/*.crt) ; do
		i=0
		# pas déjà été promu signataire
		[ -d "$dir_ca/$( basename "${cert%.crt}" )" ] && let i++
		[ "$( can_sign "$cert" )" != "1" ] && let i++
		[ "$( is_valid "$cert" )" != "1" ] && let i++
		[ $i -eq 0 ] && echo "$cert"
	done
))
[ -z "$crt_file" ] && die 4 "aucun certificat sélectionné"


# calcul des noms des différents éléments de la future CA
base="$( basename "${crt_file%.crt}" )"
key_file="$dir_key/$base.key"

[ ! -f "$dir_key/$base.key" ] && die 5 "clef inaccessible"
[ ! -f "$dir_crt/$base.crt" ] && die 6 "certificat inaccessible"
[ ! -f "$dir_crt/$base-chain.pem" ] && die 7 "chaine inaccessible"


# vérifier la clef
[ "$( match "$crt_file" "$key_file" )" != "1" ] && die 8 "Clef privée introuvable/inaccessible/mal nommée"


# création de la structure de la nouvelle CA
mkdir "$dir_ca/$base"
mkdir "$dir_ca/$base/db"
mkdir "$dir_ca/$base/private"


# déplacer les fichier de l'identifier à promouvoir (protection clef et mise en forme CA)
mv "$dir_key/$base.key" "$dir_ca/$base/private"
mv "$dir_crt/$base.crt" "$dir_ca/$base"
mv "$dir_crt/$base-chain.pem" "$dir_ca/$base"


# un peu de sécu
chmod 700 "$dir_ca/$base/private"
chmod 400 "$dir_ca/$base/private/$base.key"


# créer les éléments d'une CA
# le cp /dev/null purge la destination si elle existe
cp /dev/null "$dir_ca/$base/db/$base.db"
cp /dev/null "$dir_ca/$base/db/$base.db.attr"
echo 01 >    "$dir_ca/$base/db/$base.crt.srl"
echo 01 >    "$dir_ca/$base/db/$base.crl.srl"


# générer la chaine (RFC-5246 7.4.2)
# 1) le cert final, 2) la CA qui a signé [1], 3) la racine qui a signé [2]


# générer une configuration
# fonction ?
# demander des paramètres ?


# générer une crl
#crl.sh force "$dir_cfg/$base.conf"
#openssl ca -gencrl -config "$dir_cfg/$base.conf" -out "$dir_crl/$base.crl"
