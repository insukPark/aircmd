#!/bin/sh

#read GPIO 17
if [ ! -e /sys/class/gpio/gpio17 ]; then
	echo 17 > /sys/class/gpio/export
	echo in > /sys/class/gpio/gpio17/direction
fi
if [ ! -e /sys/class/gpio/gpio5 ]; then
	echo 5 > /sys/class/gpio/export
	echo out > /sys/class/gpio/gpio5/direction
fi

if [[ "$(cat /sys/class/gpio/gpio17/value)" -eq 1 ]]; then	#if [ $1 == '2g' ]; then
	echo "2.4G, control GPIO 5 to high" > /dev/console
        echo 1 > /sys/class/gpio/gpio5/value

	uci set wireless.default_radio1.disabled='1'
	uci set wireless.radio1.disabled='1'
	uci del wireless.default_radio0.disabled
	uci del wireless.radio0.disabled
	uci commit wireless
	/sbin/wifi reload

	echo 1 > /root/2g-switch
else								#elif [ $1 == '5g' ]; then
	echo "5G, control GPIO 5 to low" > /dev/console
        echo 0 > /sys/class/gpio/gpio5/value

	uci set wireless.default_radio0.disabled='1'
	uci set wireless.radio0.disabled='1'
	uci del wireless.default_radio1.disabled
	uci del wireless.radio1.disabled
	uci commit wireless
	/sbin/wifi reload

	rm -rf /root/2g-switch
fi
