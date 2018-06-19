#!/bin/sh
# mise a jour des crl suivant liste des configs
# et envoi crt + crl sur websrv
#
# crl/nc-email-ca.crl
# crl/nc-root-ca.crl
# crl/nc-software-ca.crl
# crl/nc-tls-ca.crl
# etc/nc-email-ca.conf
# etc/nc-root-ca.conf
# etc/nc-software-ca.conf
# etc/nc-tls-ca.conf
#
# FCRL FCFG

for FCRL in $(ls -1 crl/*.crl); do
    FCFG=`basename $FCRL`
    FCFG=etc/${FCFG%crl}conf
    openssl ca -gencrl -config "$FCFG" -out "$FCRL"
done

scp -B -P 51022 /mnt/sda1/pki/crl/*.crl cnvt.fr:/mnt/sda1/www/pki.cnvt.fr/>/dev/null
scp -B -P 51022 /mnt/sda1/pki/ca/*.crt cnvt.fr:/mnt/sda1/www/pki.cnvt.fr/>/dev/null

#echo `date`>>/mnt/sda1/logs/crl.log
