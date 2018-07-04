#!/bin/sh

dir_ca=ca
dir_cfg=etc
dir_key=req
dir_req=req
dir_crt=req
dir_crl=crl
dir_log=logs
ext_req=_ext
ext_ca=_ext
ext_crl=_ext

EC="Courbe elliptique"
RSA="Paire RSA"

function slct () {
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

function s () {
	case $1 in
		key) openssl pkey -in "$2" -pubout -outform pem | sha1sum ;;
		csr) openssl req  -in "$2" -pubkey -outform pem -noout | sha1sum ;;
		crt) openssl x509 -in "$2" -pubkey -outform pem -noout | sha1sum ;;
		*) echo "_" ;;
	esac
}

function can_sign () {
	local sign=0

	for a in "Certificate Sign" "CRL Sign" "CA:TRUE"; do
		[ $( openssl x509 -in "$1" -noout -text | grep -ic "$a" ) -ge 1 ] && let sign++
	done

	[ $sign -eq 3 ] && echo 0 || echo 1
}

function openssl_time2epoch () {
	local M J H A

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
	[ "$2" -le 9 ] && J=0$2 || J=$2
	H=$3
	A=$4

	date -d "$A-$M-$J $H" +%s
}

function seek_ext () {
	grep -e "\s*\[.*$1\s*\]\s*" "$2" | sed -r 's/\s*\[\s*//g' | sed -r 's/\s*\]\s*//g' | tr '\n' ' '
}

function curve_list ()  {
	# openssl ecparam -list_curves | grep -e "^\s\s.*" | sed 's/:.*//g' | sed 's/\s*//g'
	echo secp112r1 secp521r1 secp384r1 prime256v1
}

function is_valid () {
	echo 1
}

function die () {
	echo "$2"
	exit $1
}
