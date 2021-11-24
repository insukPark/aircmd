#!/bin/sh

if [ "$1" == "start" ]; then
	echo "start" > /var/vt_wps_command
elif [ "$1" == "stop" ]; then
	/root/vt_wps.sh stop
elif [ ${1} == "mode" ] && [ ${2} == "on" ]; then
	echo "modeon" > /var/vt_wps_command
elif [ ${1} == "mode" ] && [ ${2} == "off" ]; then
	/root/vt_wps.sh mode off
elif [ "$1" == "timeout" ]; then
        if [ -z $2 ]; then
                echo 120 > /root/config/wps-timeout
        else
                echo $2 > /root/config/wps-timeout
        fi
else
        echo "Usage: vt_wps_action.sh <mode | start | stop | timeout> [option]" > /dev/console
        echo "       [option]: mode    - <on | off>" > /dev/console
        echo "                 timeout - [120,240,360,480, ~ 65535, 120s intervals]" > /dev/console
fi

return 0
