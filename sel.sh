#!/bin/sh

function slct () {
	local i r c

	for A in "$@" ; do
		# contruction de l'index i
		let i+=1

		# obtention de l'index max
		map="$i"

		# mapping
		eval map$i=\"$A\"
		
		# affichage
		printf "\t%2d. %s\n" "$i" "$A" >&2
	done

	while [ -z $r ] ; do
		# demande du choix
		read -p "Enter selection ( 1 - $map ) or (q)uit: " c

		# sortie demandée ?
		[ "$c" = "q" ] && break

		# élimination des réponses non numériques
		[ "$c" -eq "$c" ] 2>/dev/null
		[ $? -ne 0 ] && continue
		
		# sommes-nous dans la bonne plage numérique ?
		[ $c -ge 1 -a $c -le $map ] && r="$(eval echo \$map$c)"
	done

	printf "%s" "$r"
}
