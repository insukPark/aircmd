#!/bin/sh

#read GPIO 17
if [ $1 == '2g' ]; then
	echo "2.4G, control GPIO 5" > /dev/console
	uci set wireless.default_radio1.disabled='1'
	uci set wireless.radio1.disabled='1'
	uci del wireless.default_radio0.disabled
	uci del wireless.radio0.disabled
	uci commit wireless
	/sbin/wifi reload
elif [ $1 == '5g' ]; then
	echo "5G, control GPIO 5" > /dev/console
	uci set wireless.default_radio0.disabled='1'
	uci set wireless.radio0.disabled='1'
	uci del wireless.default_radio1.disabled
	uci del wireless.radio1.disabled
	uci commit wireless
	/sbin/wifi reload
fi
