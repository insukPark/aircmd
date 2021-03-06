#! /bin/sh

echo "PARKIS: vtloop.sh" > /dev/console

sec=1

wlan0disable=0
wlan0disablecnt=0
wlan1disable=0
wlan1disablecnt=0

select2gswitchcnt=0
select5gswitchcnt=0

if [[ -e /root/config/wps-mode-always-on ]]; then
	rm -rf /root/config/wps-mode-always-on
	logger -t WPS execute /root/vt_wps.sh mode on in vtloop.sh
	/root/vt_wps.sh mode on &
fi

while true; do

# /root/vt_wps.sh start || /root/vt_wps.sh mode on
	if [[ -e /var/vt_wps_command ]]; then
		wpscmd=$(cat /var/vt_wps_command)
		rm -rf /var/vt_wps_command
		if [[ $wpscmd == "start" ]]; then
			/root/vt_wps.sh start &
		elif [[ $wpscmd == "modeon" ]]; then
			/root/vt_wps.sh mode on &
		fi
	fi

# off 2.4G/5G LED for non-using wifi
#	if [[ ! -z "$(uci show wireless | grep "wireless.default_radio0.disabled='1'")" ]]; then
	if [[ ! -z "$(uci show wireless | grep "radio0.disabled='1'")" ]]; then
		if [ ${wlan0disable} == 0 ]; then
			if [ $wlan0disablecnt -ge 5 ]; then
				echo 1 > /sys/devices/pci0000:00/0000:00:00.0/0000:01:00.0/leds/mt76-phy0/brightness
#echo "w 0" > /dev/console
				let wlan0disable=wlan0disable+1
				let wlan0disablecnt=0
			else
				let wlan0disablecnt=wlan0disablecnt+1
			fi
		elif [ $wlan0disablecnt -ge 10 ]; then
			echo 1 > /sys/devices/pci0000:00/0000:00:00.0/0000:01:00.0/leds/mt76-phy0/brightness
			let wlan0disablecnt=0
		else
			let wlan0disablecnt=wlan0disablecnt+1
		fi
	# "==" operand is ok, but ">=" is unknown operand
	elif [ ${wlan0disable} -ge 1 ]; then
		let wlan0disable=0
		let wlan0disablecnt=0
	fi

#	if [[ ! -z "$(uci show wireless | grep "wireless.radio1.disabled='1'")" ]]; then
	if [[ ! -z "$(uci show wireless | grep "radio1.disabled='1'")" ]]; then
		if [ ${wlan1disable} == 0 ]; then
			if [ $wlan1disablecnt -ge 5 ]; then
#echo "w 1" > /dev/console
				echo 1 > /sys/devices/pci0000:00/0000:00:01.0/0000:02:00.0/leds/mt76-phy1/brightness
				let wlan1disable=wlan1disable+1
				let wlan1disablecnt=0
			else
				let wlan1disablecnt=wlan1disablecnt+1
			fi
		elif [ $wlan1disablecnt -ge 10 ]; then
			echo 1 > /sys/devices/pci0000:00/0000:00:01.0/0000:02:00.0/leds/mt76-phy1/brightness
			let wlan1disablecnt=0
		else
			let wlan1disablecnt=wlan1disablecnt+1
		fi
	elif [ ${wlan1disable} -ge 1 ]; then
		let wlan1disable=0
		let wlan1disablecnt=0
	fi

# check selection switch and apply 2.4G/5G only
	if [ ! -e /root/config/wifi-disable ]; then
		# read GPIO 17, maybe low means 2G && high means 5G
		if [ ! -e /sys/class/gpio/gpio17 ]; then
			echo 17 > /sys/class/gpio/export
			echo in > /sys/class/gpio/gpio17/direction
		fi
		if [ ! -e /sys/class/gpio/gpio5 ]; then
			echo 5 > /sys/class/gpio/export
			echo out > /sys/class/gpio/gpio5/direction
		fi

		if [[ "$(cat /sys/class/gpio/gpio17/value)" -eq 1 ]]; then # 1 means 2.4G  #if [ -e /root/2g-switch ]; then
			if [ $select2gswitchcnt -eq 1 ]; then
echo "2.4G ! control GPIO 5 to high" > /dev/console
				echo 1 > /sys/class/gpio/gpio5/value
				uci set wireless.default_radio1.disabled='1'
				uci set wireless.radio1.disabled='1'
		 		uci del wireless.default_radio0.disabled
		 		uci del wireless.radio0.disabled
		 		uci commit wireless
		 		/sbin/wifi reload

				let select2gswitchcnt=2
			elif [ $select2gswitchcnt -eq 0 ]; then
				# maybe after booting, so need to change
				let select2gswitchcnt=2
			elif [ $select5gswitchcnt -eq 2 ]; then
				# change wifi 2g/5g next turn
				let select2gswitchcnt=1
				let select5gswitchcnt=0
			fi
		else
			if [ $select5gswitchcnt -eq 1 ]; then
echo "5G ! control GPIO 5 to low" > /dev/console
				echo 0 > /sys/class/gpio/gpio5/value
				uci set wireless.default_radio0.disabled='1'
				uci set wireless.radio0.disabled='1'
				uci del wireless.default_radio1.disabled
				uci del wireless.radio1.disabled
				uci commit wireless
				/sbin/wifi reload

				let select5gswitchcnt=2
			elif [ $select5gswitchcnt -eq 0 ]; then
				# maybe after booting, so need to change
				let select5gswitchcnt=2
			elif [ $select2gswitchcnt -eq 2 ]; then
				# change wifi 2g/5g next turn
				let select5gswitchcnt=1
				let select2gswitchcnt=0
			fi
		fi
	else
		let select2gswitchcnt=0
		let select5gswitchcnt=0
	fi

# sleep time for loop
	sleep $sec
done
