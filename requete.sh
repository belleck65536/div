#!/bin/sh
# permet la creation d'une requete de certificat puis signe le certificat
#
# WORKDIR NOMFIC REQCFG MODREQ

WORKDIR=certs/

while [ "$NOMFIC" = "" ]; do
	read -p "Nom de fichier pour la requête (l'extension sera ajoutée automatiquement) : " NOMFIC
	if [ -f "$WORKDIR$NOMFIC.csr" -o -f "$WORKDIR$NOMFIC.key" ]; then
		echo "nom de requête déjà utilisé"
		NOMFIC=""
	fi;
done


echo "type de clef :
1. Courbe eliptique
2. Paire RSA"
while [ -z "$KEYTYPE" ]; do
	read KEYTYPEi
	case $KEYTYPEi in
		1)
			KEYTYPE="ecparam -genkey -noout -name"
			echo "courbe :
			1. secp521r1
			2. secp384r1
			3. prime256v1"
			while [ -z $KEYOPT ]; do
				read KEYOPTi
				case $KEYOPTi in
					1)
						KEYOPT="secp521r1"
					;;
					2)
						KEYOPT="secp384r1"
					;;
					3)
						KEYOPT="prime256v1"
					;;
					"")
						echo "???"
					;;
					*)
						echo "Choix incorrect"
					;;
				esac
			done
		;;
		2)
			KEYTYPE="genrsa"
			echo "longueur :"
			while [ -z $KEYOPT ]; do
				read KEYOPTi
				case $KEYOPTi in
					1024|2048|4096|8192)
						KEYOPT=$KEYOPTi
					;;
					"")
						echo "???"
					;;
					*)
						echo "Choix incorrect"
					;;
				esac
			done
		;;
		"")
			echo "???"
		;;
		*)
			echo "Choix incorrect"
		;;
	esac
done


echo "Modèle de requête :
1. Serveur SSL
2. Client SSL
3. Certificat pour signature de code
4. Certificat d'identité numérique (e-mail)"
while [ -z $REQCFG ]; do
	read MODREQ
	case $MODREQ in
		1)
			REQCFG=server
		;;
		2)
			REQCFG=client
		;;
		3)
			REQCFG=codesign
		;;
		4)
			REQCFG=email
		;;
		"")
			echo "???"
		;;
		*)
			echo "Choix incorrect"
		;;
	esac
done


echo "Définition du SAN
élements : DNS | IP | URI | email | RID | dirName | otherNmae
ex : DNS:www.example.com,IP:0.0.0.0
le syubjectAtlName ne peut être vide"
while [ -z "$SANC" ]; do
	read SANC
	case $SANC in
		"")
			echo "???"
		;;
		*)
			echo "Appuyez sur une touche pour continuer"
			read dummy
		;;
	esac
done

	
openssl $KEYTYPE $KEYOPT -out "$WORKDIR$NOMFIC.key"
SAN=$SANC openssl req -new -config etc/nc-$REQCFG.conf -out "$WORKDIR$NOMFIC.csr" -key "$WORKDIR$NOMFIC.key"
./signat.sh $REQCFG "$WORKDIR$NOMFIC.csr"

