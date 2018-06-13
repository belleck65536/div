#!/bin/busybox ash
#
# faire un choix parmi les fichiers d'un répertoire fourni en entrée

function slct () {

	# parser l'entrée
	[ -n "$1" ] && F="$1" || F="$PWD"

	#tester l'existence du repertoire
	[ ! -d "$F" ] && exit 1

	#sortie temporaire
	tf=$(mktemp)

	#lister les fichiers, présenter, demander le choix
	find "$F" -maxdepth 1 -type f | busybox awk -v answer="$tf" '
	function read_console() {
		"head -1 < /dev/tty" | getline results
		close("head -1 < /dev/tty")
		return results
	}

	{ A[NR] = $0 }

	END {
		if ( NR < 1 ) break
		do {
			for (l=1; l<=NR; l++) { printf "\t%2d. %s\n", l, A[l] }
			printf "\nEnter selection ( 1 - %s ) or (q)uit: ", NR
			selection = read_console()
			if (selection == "q") break
			selection = selection + 0
		} while (selection < 1 || selection > NR)
		if (selection != "q") print A[selection] > answer
	} '

	#afficher le choix
	cat "$tf"

	# nettoyer
	rm -f "$tf"

}
