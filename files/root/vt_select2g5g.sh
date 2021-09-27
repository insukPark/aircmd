#!/bin/sh

if [ $1 == '2g' ]; then
	uci set wireless.default_radio1.disabled='1'
	uci del wireless.default_radio0.disabled
	uci commit wireless
	/sbin/wifi reload
elif [ $1 == '5g' ]; then
	uci set wireless.default_radio0.disabled='1'
	uci del wireless.default_radio1.disabled
	uci commit wireless
	/sbin/wifi reload
fi
