#!/bin/bash

RED='\033[0;31m'
END='\033[0m'

go_available () {
    type go >/dev/null 2>&1 || { printf >&2 "${RED}[ERROR] GO is required to proceed but it's not installed. Aborting.${END}\\n"; return 1; }
}

# Enumerates subdomains using subfinder (https://github.com/Ice3man543/subfinder)
# TO DO add DNS resolution + port scan
enumerate_subdomains () {
    if ! go_available; then return 1; fi
    if ! [ -d subfinder ]; then
        echo "[*] Downloading subfinder..."
        git clone "https://github.com/Ice3man543/subfinder"
        cd subfinder
        go build
        cd .. # TO DO this seems dangerous, find a better way (also check for git availability)
   fi
   echo "[*] Running subfinder on $DOMAIN..."
   subfinder/subfinder -d $DOMAIN -nw -o $DOMAIN-subdomains.txt --silent --timeout 10 -b -w lists/subdomains
   echo "[*] Done. Found $(cat $DOMAIN-subdomains.txt |wc -l) subdomains."
}

# Checks for common configuration files, dotfiles, etc. using meg (https://github.com/tomnomnom/meg)
check_common_files () {
    if ! go_available; then return 1; fi
    if ! [ -d meg ]; then
        echo "[*] Downloading meg..."
        git clone "https://github.com/tomnomnom/meg"
        cd meg
        go get -u github.com/tomnomnom/rawhttp # This is just to get the rawhttp dependency in place.
        go build
        cd .. # TO DO this seems dangerous, find a better way (also check for git availability)
    fi
    echo "[*] Running meg using lists/dotfiles on $DOMAIN..."
    meg/meg --delay 400 lists/dotfiles https://$DOMAIN
    grep -Hnri "$DOMAIN.*200 OK" out/index
}

if [[ $1 == '' ]] || [[ $1 == '-h' ]] || [[ $1 == '--help' ]]; then
    echo "Usage: <domain_name>"
    exit 1
fi

DOMAIN=$1

read -p "[*] Do you wish to enumerate subdomains on ${DOMAIN}? [Y/n] " yn
case $yn in
    [nN]* ) :;;
    * ) enumerate_subdomains;;
esac

read -p "[*] Do you wish to check for common configuration files, dotfiles etc.? [Y/n] " yn
case $yn in
    [nN]* ) :;;
    * ) check_common_files;;
esac

echo "[*] That's it, bye!"
