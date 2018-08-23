#!/bin/sh
cd "$(dirname "$0")"
dir_ca=ca
dir_cfg=etc
dir_key=req
dir_req=req
dir_crt=req
dir_crl=crl
dir_log=logs
ext_req=_ext
ext_ca=ext_ca_
ext_crl=_ext


for fld in "$dir_ca" "$dir_cfg" "$dir_key" "$dir_req" "$dir_crt" "$dir_crl" "$dir_log" ; do
	[ ! -d "$fld" ] && mkdir "$fld"
done


EC="Courbe elliptique"
RSA="Paire RSA"
tab=$( printf "\t" )

let NOW=$( date +%s )+86400*1


function slct {
	local i r c
	[ $# -lt 1 ] && return

	for A in "$@" ; do
		let i+=1
		eval local m$i=\"$A\"
		printf "\t%2d. %s\n" "$i" "$A" >&2
	done

	while [ -z "$r" ] ; do
		read -p "Enter selection ( 1 - $i ) or (q)uit: " c
		[ "$c" = "q" ] && break
		[ "$c" -eq "$c" ] 2>/dev/null
		[ $? -ne 0 ] && continue
		[ "$c" -ge 1 -a "$c" -le $i ] && eval r="\$m$c"
	done

	printf "%s" "$r"
}

function match {
	case "${1##*.}" in
		key) as="$( openssl pkey -in "$1" -pubout -outform pem | sha1sum )" ;;
		csr) as="$( openssl req  -in "$1" -pubkey -outform pem -noout | sha1sum )" ;;
		crt) as="$( openssl x509 -in "$1" -pubkey -outform pem -noout | sha1sum )" ;;
		*) as="_" ;;
	esac
	case "${2##*.}" in
		key) bs="$( openssl pkey -in "$2" -pubout -outform pem | sha1sum )" ;;
		csr) bs="$( openssl req  -in "$2" -pubkey -outform pem -noout | sha1sum )" ;;
		crt) bs="$( openssl x509 -in "$2" -pubkey -outform pem -noout | sha1sum )" ;;
		*) bs="_" ;;
	esac
	[ "$as" = "$bs" ] && echo "1" || echo "0"
}

function can_sign {
	local sign=0

	for a in "Certificate Sign" "CRL Sign" "CA:TRUE"; do
		[ $( openssl x509 -in "$1" -noout -text | grep -ic "$a" ) -ge 1 ] && let sign++
	done

	[ $sign -eq 3 ] && echo 1 || echo 0
}

function openssl_time2epoch {
	local M z

	case $1 in
		Jan) M=01 ;;
		Feb) M=02 ;;
		Mar) M=03 ;;
		Apr) M=04 ;;
		May) M=05 ;;
		Jun) M=06 ;;
		Jul) M=07 ;;
		Aug) M=08 ;;
		Sep) M=09 ;;
		Oct) M=10 ;;
		Nov) M=11 ;;
		Dec) M=12 ;;
		*)   M=__ ;;
	esac
	[ "$2" -le 9 ] && z=0

	date -d "$4-$M-$z$2 $3" +%s
}

function die {
	echo "$2" >&2
	exit $1
}

function seek_ext {
	grep -e "\s*\[.*$1.*\]\s*" "$2" | sed -r 's/\s*\[\s*//g' | sed -r 's/\s*\]\s*//g' | tr '\n' ' '
}

function curve_list {
	# openssl ecparam -list_curves | grep -e "^\s\s.*" | sed 's/:.*//g' | sed 's/\s*//g'
	echo secp112r1 secp521r1 secp384r1 prime256v1
}

function is_valid {
	echo 1
}

function conf_gen {
	echo "$1"
	# dupliquer un fichier en modifier des modèles de données ?
	# demander des paramètres et tout verser à la fin ?
}

function duree {
	unt=${1: -1}
	qte=${1%$unt}
	[ -z "$qte" ] && qte=0

	case $unt in
		y|Y) mltp=365 ;;
		m|M) mltp=30 ;;
		w|W) mltp=7 ;;
		d|D) mltp=1 ;;
		*) mltp=0 ;;
	esac
	
	let days=$qte*$mltp
	echo -n $days
}
