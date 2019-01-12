#!/bin/bash
#
# This script is used as a cronjob to perform update to DNS Settings.
# It queries opennic API endpoint and gets DNS Server list then update dnsmasq and pihole setupvars files with the retrieved DNS server IPs
#

# API call to get DNS servres
# Get 2 random IPv4 DNS with anonymized logs
curl -s "https://api.opennicproject.org/geoip/?bare&res=2@rnd=true&anon=true&ipv=4" --output /tmp/ipv4
# Get 2 random IPv6 DNS with anonymized logs
curl -s "https://api.opennicproject.org/geoip/?bare&res=2@rnd=true&anon=true&ipv=6" --output /tmp/ipv6

# If both IPV4 and IPV6 are retrieved only then perform the update to the files
if  [ -f "/tmp/ipv4" ] && [ -f "/tmp/ipv6" ]; then

    # Combining both files into one
    cat /tmp/ipv4 /tmp/ipv6 > /tmp/ip

    # Delete current DNS settings from setup and pihole.conf file
    sed -i '/^PIHOLE_DNS/d' /etc/pihole/setupVars.conf
    sed -i '/^server/d' /etc/dnsmasq.d/01-pihole.conf

    # Loop through DNS IPs and echo them into setup and pihole.conf file
    while read ip
    do
        echo PIHOLE_DNS_${i}=${ip}#53 >> /etc/pihole/setupVars.conf
        echo server=${ip}#53 >> /etc/dnsmasq.d/01-pihole.conf
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
