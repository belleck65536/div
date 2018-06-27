#!/bin/sh

dir_ca=ca/
dir_cfg=etc/
dir_req=req/
dir_certs=certs/
dir_logs=logs/

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
		*) echo "\#" ;;
	esac
}

function can_sign () {
	local sign=0

	for a in "Certificate Sign" "CRL Sign" "CA:TRUE"; do
		[ $( openssl x509 -in "$1" -noout -text | grep -ic "$a" ) -ge 1 ] && let sign++
	done

	[ $sign -eq 3 ] && return 1 || return 0
}

function openssl_time2epoch () {
	local M J H A

	J=$2
	H=$3
	A=$4

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

	date -d "$A-$M-$J $H" +%s
}

function is_valid () {
	echo "invalide"
}
