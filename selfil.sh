#!/bin/busybox ash

function slct () {

 # sortie temporaire
 tf=$(mktemp)

 # présenter, demander le choix
 echo "$@" | busybox awk -v answer="$tf" '
 function read_console() {
  "head -1 < /dev/tty" | getline results
  close("head -1 < /dev/tty")
  return results
 }

 { A[NR] = $0 }

 END {
  if ( NR < 1 ) break
  for (l=1; l<=NR; l++) { printf "\t%2d. %s\n", l, A[l] }
  do {
   printf "Enter selection ( 1 - %s ) or (q)uit: ", NR
   selection = read_console()
   if (selection == "q") break
   selection = selection + 0
  } while (selection < 1 || selection > NR)
  if (selection != "q") print A[selection] > answer
 } '

 # afficher le choix
 cat "$tf"

 # nettoyer
 rm -f "$tf"

}
