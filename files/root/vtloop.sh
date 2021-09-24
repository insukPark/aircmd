#! /bin/sh

while true; do
	if [[ ! -z "$(uci show wireless | grep "wireless.radio0.disabled='1'")" ]]; then
#		if [[ ! -e /var/wlan0disable ]]; then
			echo 1 > /sys/devices/pci0000:00/0000:00:00.0/0000:01:00.0/leds/mt76-phy0/brightness
#			echo 1 > /var/wlan0disable
#		fi
#	elif [[ -e /var/wlan0disable ]]; then
#		rm -rf /var/wlan0disable
	fi

	if [[ ! -z "$(uci show wireless | grep "wireless.radio1.disabled='1'")" ]]; then
#		if [[ ! -e /var/wlan1disable ]]; then
			echo 1 > /sys/devices/pci0000:00/0000:00:01.0/0000:02:00.0/leds/mt76-phy1/brightness
#			echo 1 > /var/wlan1disable
#		fi
#	elif [[ -e /var/wlan1disable ]]; then
#		rm -rf /var/wlan1disable
	fi

	sleep 1
done
