#!/bin/sh

if [ -z "$1" ]; then
	echo "Usage: vt_wps.sh <mode | start | stop | timeout> [option]" > /dev/console
	echo "       [option]: mode    - <on | off>" > /dev/console
	echo "                 timeout - [120,240,360,480, ~ 65535, 120s intervals]" > /dev/console

	return 0
fi

if [[ -e /root/config/wps-timeout ]]; then
	wpstmout=$(cat /root/config/wps-timeout)
else
	wpstmout=120
fi
if [[ ! -z "${wpstmout//[0-9]/}" ]]; then	# check number
	wpstmout=120
fi
if [[ $wpstmout -lt 120 ]]; then
	wpstmout=120
fi

wpssleeptime=2
let wpstmoutcnt=wpstmout/wpssleeptime
let wpstmoutcntmod=wpstmout%wpssleeptime
[ $wpstmoutcntmod -gt 0 ] && let wpstmoutcnt=wpstmoutcnt+1

if [ "$1" == "start" ]; then
	logger -t WPS wps start command received
	rm -rf /var/wps-stop
	echo "WPS start command..." > /dev/console
	WPSLED=$(ls /sys/devices/platform/leds/leds/)
	echo timer > /sys/devices/platform/leds/leds/$WPSLED/trigger
	# -gt 3 means keep going if remain-time over 6sec
	while [ $wpstmoutcnt -gt 3 ]; do
		cd /var/run/hostapd
		for socket in *; do
			[ -S "$socket" ] || continue
			hostapd_cli -i "$socket" wps_pbc
			logger -t WPS "$socket" actived
		done

		sleep $wpssleeptime
		cnt=1
		for socket in *; do
			[ -S "$socket" ] || continue
			for iii in $(seq 1 $wpstmoutcnt); do
				if [[ -e /var/wps-stop ]]; then
					logger -t WPS deactived with stop-command
					rm -rf /var/wps-stop
					for socket in *; do
						[ -S "$socket" ] || continue
						hostapd_cli -i "$socket" wps_cancel
						logger -t WPS "$socket" canceled
					done
					echo default-on > /sys/devices/platform/leds/leds/$WPSLED/trigger
					exit 0
				elif [[ ! -z "$(hostapd_cli -i "$socket" wps_get_status | grep 'PBC Status: Overlap')" ]]; then
					logger -t WPS deactived with overlap status
					killall -9 hostapd
					exit 0
				elif [[ ! -z "$(hostapd_cli -i "$socket" wps_get_status | grep 'PBC Status: Timed-out')" ]]; then
					let wpstmoutcnt=wpstmoutcnt-60
					break
				elif [[ ! -z "$(hostapd_cli -i "$socket" wps_get_status | grep 'PBC Status: Disabled')" ]]; then
					let wpstmoutcnt=0
					echo default-on > /sys/devices/platform/leds/leds/$WPSLED/trigger
					exit 0
				elif [[ ! -z "$(hostapd_cli -i "$socket" wps_get_status | grep 'PBC Status: Active')" ]]; then
					sleep $wpssleeptime
					let cnt=cnt+1
					if [ $cnt == $wpstmoutcnt ]; then
						logger -t WPS deactived with timeout
						for socket in *; do
							[ -S "$socket" ] || continue
							hostapd_cli -i "$socket" wps_cancel
							logger -t WPS "$socket" canceled
						done
						echo default-on > /sys/devices/platform/leds/leds/$WPSLED/trigger
						exit 0
					fi
				fi
			done
		done
	done

	echo default-on > /sys/devices/platform/leds/leds/$WPSLED/trigger
elif [ "$1" == "stop" ]; then
	logger -t WPS wps stop command received
	echo "WPS stop command..." > /dev/console
	echo 1 > /var/wps-stop
#	cd /var/run/hostapd
#	for socket in *; do
#		[ -S "$socket" ] || continue
#		hostapd_cli -i "$socket" wps_cancel
#		logger -t WPS "$socket" canceled
#	done
elif [ ${1} == "mode" ] && [ ${2} == "on" ]; then
	echo "WPS always-on mode command..." > /dev/console
	if [[ -e /root/config/wps-mode-always-on ]]; then
		wpspid="$(cat /root/config/wps-mode-always-on)"
		if [ ! -z "$(ps | grep ^$wpspid)" ]; then
			echo "already 'vt_wps.sh mode on'..." > /dev/console
			logger -t WPS wps always-on mode command received again in always-on
			return 0
		fi
	fi
	logger -t WPS wps always-on mode command received
	echo $$ > /root/config/wps-mode-always-on

	cur_active=0
	WPSLED=$(ls /sys/devices/platform/leds/leds/)
	while [[ -e /root/config/wps-mode-always-on ]]; do
		echo timer > /sys/devices/platform/leds/leds/$WPSLED/trigger
		while [[ -e /root/config/wifi-disable ]]; do
			sleep $wpssleeptime
			if [[ ! -e /root/config/wps-mode-always-on ]]; then
				echo default-on > /sys/devices/platform/leds/leds/$WPSLED/trigger
				logger -t WPS exit-wps-always-on mode

				# terminated always-on mode
				exit 0
			fi
		done

#echo "always-on again ..." > /dev/console
		cd /var/run/hostapd
		for socket in *; do
			[ -S "$socket" ] || continue
			hostapd_cli -i "$socket" wps_pbc
			logger -t WPS "$socket" actived
		done

		sleep $wpssleeptime
		while true; do
			cd /var/run/hostapd
			for socket in *; do
				[ -S "$socket" ] || continue
				if [[ ! -z "$(hostapd_cli -i "$socket" wps_get_status | grep 'PBC Status: Active')" ]]; then
					let cur_active=1
					sleep $wpssleeptime
				elif [[ ! -z "$(hostapd_cli -i "$socket" wps_get_status | grep 'PBC Status: Overlap')" ]]; then
					logger -t WPS reactived with overlap status
					killall -9 hostapd
					sleep $wpssleeptime
					sleep $wpssleeptime
					let cur_active=0
				fi
			done

			if [[ ! -e /root/config/wps-mode-always-on ]]; then
				for socket in *; do
					[ -S "$socket" ] || continue
					hostapd_cli -i "$socket" wps_cancel
					logger -t WPS "$socket" canceled
				done

				echo default-on > /sys/devices/platform/leds/leds/$WPSLED/trigger
				logger -t WPS exit-wps-always-on mode

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
	logger -t WPS terminate-wps-always-on mode
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
