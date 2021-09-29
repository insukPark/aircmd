#!/bin/sh

if [ -z "$1" ]; then
	echo "Usage: vt_wps.sh <mode | start | stop | timeout> [option]" > /dev/console
	echo "       [option]: mode    - <on | off>" > /dev/console
	echo "                 timeout - [120,240,360,480, ~ 65535, 120s intervals]" > /dev/console

	return 0
fi

if [[ -e /root/config/wps-timeout ]]; then
	TMOUT=$(cat /root/config/wps-timeout)
else
	TMOUT=120
fi
if [[ ! -z "${TMOUT//[0-9]/}" ]]; then
	TMOUT=120
fi
if [[ $TMOUT -lt 120 ]]; then
	TMOUT=120
fi

SLEEPTIME=2
let TMOUTCNT=TMOUT/SLEEPTIME
let TMOUTCNTMOD=TMOUT%SLEEPTIME
[ $TMOUTCNTMOD -gt 0 ] && let TMOUTCNT=TMOUTCNT+1

if [ "$1" == "start" ]; then
	logger -t WPS wps start command received
	echo "WPS start command..." > /dev/console
	WPSLED=$(ls /sys/devices/platform/leds/leds/)
	echo timer > /sys/devices/platform/leds/leds/$WPSLED/trigger
	cd /var/run/hostapd
	for socket in *; do
		[ -S "$socket" ] || continue
		hostapd_cli -i "$socket" wps_pbc
		logger -t WPS "$socket" actived
	done

	sleep $SLEEPTIME
	cnt=1
	for socket in *; do
		[ -S "$socket" ] || continue
		for i in $(seq 1 $TMOUTCNT); do
			if [[ ! -z "$(hostapd_cli -i "$socket" wps_get_status | grep 'PBC Status: Active')" ]]; then
				sleep $SLEEPTIME
				let cnt=cnt+1
				if [ $cnt == $TMOUTCNT ]; then
					logger -t WPS deactived with timeout
					echo default-on > /sys/devices/platform/leds/leds/$WPSLED/trigger
					exit 0
				fi
			fi
		done
	done

	echo default-on > /sys/devices/platform/leds/leds/$WPSLED/trigger
elif [ "$1" == "stop" ]; then
	logger -t WPS wps stop command received
	echo "WPS stop command..." > /dev/console
#	if [[ -z "$( ps | grep "vt_wps.sh start")" ]]; then
#		logger -t WPS no actived process vt_wps.sh
#		exit 0
#	fi

	cd /var/run/hostapd
	for socket in *; do
		[ -S "$socket" ] || continue
		hostapd_cli -i "$socket" wps_cancel
		logger -t WPS "$socket" canceled
	done
elif [ ${1} == "mode" ] && [ ${2} == "on" ]; then
	echo 1 > /root/config/wps-mode-always-on
	echo "WPS always-on mode command..." > /dev/console
	if [[ ! -z $(ps | grep "vt_wps.sh mode on") ]]; then
		echo "already 'vt_wps.sh mode on'..." > /dev/console
		logger -t WPS wps always-on mode command received again in always-on
		return 0
	else
		logger -t WPS wps always-on mode command received
	fi

	cur_active=0
	WPSLED=$(ls /sys/devices/platform/leds/leds/)
	echo timer > /sys/devices/platform/leds/leds/$WPSLED/trigger
	while true; do
echo "always-on again ..." > /dev/console
		cd /var/run/hostapd
		for socket in *; do
			[ -S "$socket" ] || continue
			hostapd_cli -i "$socket" wps_pbc
			logger -t WPS "$socket" actived
		done

		sleep $SLEEPTIME
		while true; do
			cd /var/run/hostapd
			for socket in *; do
				[ -S "$socket" ] || continue
				if [[ ! -z "$(hostapd_cli -i "$socket" wps_get_status | grep 'PBC Status: Active')" ]]; then
					let cur_active=1
					sleep $SLEEPTIME
				fi
			done

			if [[ ! -e /root/config/wps-mode-always-on ]]; then
				for socket in *; do
					[ -S "$socket" ] || continue
					hostapd_cli -i "$socket" wps_cancel
					logger -t WPS "$socket" canceled
				done

				echo default-on > /sys/devices/platform/leds/leds/$WPSLED/trigger

				# terminated always-on mode
				exit 0
			fi

			if [ $cur_active -eq 0 ]; then
				break
			fi
			let cur_active=0
		done
	done

	echo default-on > /sys/devices/platform/leds/leds/$WPSLED/trigger
elif [ ${1} == "mode" ] && [ ${2} == "off" ]; then
	rm -rf /root/config/wps-mode-always-on
	logger -t WPS terminate-wps-always-on mode command received
	echo "WPS terminate always-on mode command..." > /dev/console
elif [ "$1" == "timeout" ]; then
	if [ -z $2 ]; then
		echo 120 > /root/config/wps-timeout
	else
		echo $2 > /root/config/wps-timeout
	fi
else
	echo "Usage: vt_wps.sh <mode | start | stop | timeout> [option]" > /dev/console
	echo "       [option]: mode    - <on | off>" > /dev/console
	echo "                 timeout - [120,240,360,480, ~ 65535, 120s intervals]" > /dev/console
fi

return 0
