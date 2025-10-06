#!/bin/sh
/etc/init.d/openvpn stop
sleep 3
rm /etc/openvpn/client.conf
rm /etc/openvpn/pass.txt