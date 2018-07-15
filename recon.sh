#!/bin/bash

RED='\033[0;31m'
END='\033[0m'

go_available () {
    hash go >/dev/null 2>&1 || { printf >&2 "${RED}[ERROR] GO is required to proceed but it's not installed. Aborting.${END}\\n"; return 1; }
}

enumerate_subdomains () {
    if ! go_available; then return 1; fi
    if ! [ -d subfinder ]; then
        echo "[*] Downloading subfinder..."
        git clone "https://github.com/subfinder/subfinder"
        cd subfinder
        go build
        cd $BASE_DIR
   fi
   echo "[*] Running subfinder on $DOMAIN..."
   subfinder/subfinder -d $DOMAIN -nw -o $DOMAIN-subdomains.txt --silent --timeout 10 -b -w lists/subdomains
   echo "[*] Done. Found $(cat $DOMAIN-subdomains.txt |wc -l) subdomains."
   # Remove unresolving subdomains
}

# Checks for common configuration files, dotfiles, etc. using meg (https://github.com/tomnomnom/meg)
check_common_files () {
    if ! go_available; then return 1; fi
    if ! [ -d meg ]; then
        echo "[*] Downloading meg..."
        git clone "https://github.com/tomnomnom/meg"
        cd meg
        go get -u github.com/tomnomnom/rawhttp # This is to get the rawhttp dependency in place.
        go build
        cd $BASE_DIR
    fi
    echo "[*] Running meg using lists/dotfiles on $1..."
    meg/meg --delay 100 -c 70 lists/dotfiles $1 2>/dev/null
    if [[ $1 == http* ]]; then
       grep -Hnri "$1.*20[0-9]" out/index
    else
       while read p; do
           grep -Hnri "$p.*20[0-9]" out/index
       done < $1
    fi
}

if [[ $1 == '' ]] || [[ $1 == '-h' ]] || [[ $1 == '--help' ]]; then
    echo "Usage: <domain_name>"
    exit 1
fi

DOMAIN=$1
BASE_DIR=`dirname $(readlink -f $0)`

cd $BASE_DIR # Make sure we are in the correct folder

read -p "[*] Do you wish to enumerate subdomains on ${DOMAIN}? [Y/n] " yn
case $yn in
    [nN]* ) :;;
    * ) enumerate_subdomains;;
esac

read -p "[*] Do you wish to check for common configuration files, dotfiles etc.? [Y/n] " yn
case $yn in
    [nN]* ) :;;
    # I am unlikely testing a APEX domain not running https.
    * ) check_common_files https://$DOMAIN;;
esac

read -p "[*] Do you wish to repeat for all subdomains? [Y/n]" yn
case $yn in
    [nN]* ) :;;
    * )
	sed -e 's#^#http://#' $DOMAIN-subdomains.txt > $DOMAIN-subdomains_http.txt
        sed -e 's#^#https://#'  $DOMAIN-subdomains.txt > $DOMAIN-subdomains_https.txt
        cat $DOMAIN-subdomains_h*.txt > $DOMAIN-subdomains_proto.txt
	rm $DOMAIN-subdomains_h*.txt
	check_common_files $DOMAIN-subdomains_proto.txt;;
esac

echo "[*] That's it, bye!"
