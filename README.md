# div

Mini CA basée sur openssl
Environnement Shell flavor busybox

Se placer dans un dossier pour l'exécution de la CA :
cd xxx/pki

dans le dossier de la pki, on aura :
	./ca	--> contient les bases de données des CA
				./<CA>.crt --> certificat de la CA
				./<CA>/ dossier des cert signés, nommées par leur S/N (copie du cert final)
				./<CA>/private/<CA>.key --> pkey de la CA
				./<CA>/db/ dossier de la DB
	./etc	--> fichiers de configuration pour les requêtes, les sig et les OCSP
				les CRL sont issues des CA
	./req	--> réception des requêtes de signature
	
Les emplacements configurables dans lib.sh sont :
	CA (db srl² crt )
	clef privée
	certificat signé
	requête de signature
	CRL
	config
	logs