#!/bin/sh
uci del dhcp.lan.ra_slaac
uci del dhcp.lan.ndp
uci set dhcp.lan.ra='server'
uci set dhcp.lan.ra_default='2'
uci set dhcp.lan.dhcpv6='server'
uci add_list dhcp.lan.dns='2402:4e00::'
uci commit dhcp

ip6tables_rule="ip6tables -t nat -A POSTROUTING -o eth1 -j MASQUERADE"
if ! grep -qF "$ip6tables_rule" /etc/firewall.user; then
  echo "$ip6tables_rule" >> /etc/firewall.user
fi

cat << EOF > /etc/hotplug.d/iface/99-ipv6-nat
#!/bin/sh
[ "$ACTION" = ifup ] || exit 0
[ "$INTERFACE" = wan ] || exit 0
sleep 15s
ipv6_gateway="$(ip -6 route show | grep default | sed -e 's/^.*via //g' | sed 's/ dev.*$//g')"
route -A inet6 add default gw $ipv6_gateway dev eth1
EOF

chmod a+x /etc/hotplug.d/iface/99-ipv6-nat

echo "Please reboot your CPE to apply IPv6 Nat!"
