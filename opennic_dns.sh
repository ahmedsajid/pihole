#!/bin/bash
# This script queries opennic API endpoint and gets DNS Server
# Then dumps those in dnsmasq and pihole setupvars

IPv4=`curl -s "https://api.opennicproject.org/geoip/?bare&res=2@rnd=true&anon=true&ipv=4" --output /tmp/ipv4`
IPv6=`curl -s "https://api.opennicproject.org/geoip/?bare&res=2@rnd=true&anon=true&ipv=6" --output /tmp/ipv6`

# Var for index
i=1

# If both IPV4 and IPV6 are retrieved only then perform the update to the files
if  [ -f "/tmp/ipv4" ] && [ -f "/tmp/ipv6" ]; then
    cat /tmp/ipv4 /tmp/ipv6 > /tmp/ip
    sed -i '/^PIHOLE_DNS/d' /etc/pihole/setupVars.conf
    sed -i '/^server/d' /etc/dnsmasq.d/01-pihole.conf

    while read ip
    do
        echo PIHOLE_DNS_${i}=${ip}#53 >> /etc/pihole/setupVars.conf
        echo server=${ip}#53 >> /etc/dnsmasq.d/01-pihole.conf
        i=$(($i+1))
    done < /tmp/ip
    
    # Syntax checking
    dnsmasq --test

    # Check if syntax check was OK
    if [ $? -ne 0 ];then
      exit 1
    fi

    # Restart dns
    pihole restartdns

fi

rm -rf /tmp/ipv4 /tmp/ipv6 /tmp/ip
