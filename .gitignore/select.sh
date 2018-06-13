#!/bin/busybox ash
#
# $1 is file to read from

[ "$1" == "-" ] && FILEIN=/dev/stdin || FILEIN="$1"
[ -z "$1" ] && exit 1

tf=$(mktemp)

busybox awk -v answer="$tf" '
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
} ' < "$FILEIN"


chx=$(cat "$tf")
rm -f "$tf"
printf "%s" "$chx"