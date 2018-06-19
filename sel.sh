#!/bin/sh

function slct () {
	local m i r c

	for A in "$@" ; do
		# contruction de l'index i
		let i+=1

		# obtention de l'index max
		m="$i"

		# mapping
		eval local m$i=\"$A\"
		
		# affichage
		printf "\t%2d. %s\n" "$i" "$A" >&2
	done

	while [ -z "$r" ] ; do
		# demande du choix
		read -p "Enter selection ( 1 - $m ) or (q)uit: " c

		# sortie demandée ?
		[ "$c" = "q" ] && break

		# élimination des réponses non numériques
		[ "$c" -eq "$c" ] 2>/dev/null
		[ $? -ne 0 ] && continue
		
		# sommes-nous dans la bonne plage numérique ?
		[ $c -ge 1 -a $c -le $m ] && eval r="\$m$c"
	done

	printf "%s" "$r"
}
