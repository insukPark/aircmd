#! /bin/sh

function usage
{
	echo "Usage: vt_attenuator.sh <0 ~ 31.5, 0.5 interval>" > /dev/console
	exit 0
}

if [[ -z $1 ]]; then
	usage
fi

var=${1%.5}
if [[ ! -z "${var//[0-9]/}" ]]; then       # check number
	usage
fi

if [[ -z $(echo $1 | grep .5) ]]; then
	zzumo=0
else
	zzumo=1
fi

echo $1 > /root/config/rf-att-strength

#0.25
#echo "GPIO#06 = 0" > /dev/console
if [ ! -e /sys/class/gpio/gpio6 ]; then
	echo 6 > /sys/class/gpio/export
	echo out > /sys/class/gpio/gpio6/direction
fi
echo 0 > /sys/class/gpio/gpio6/value

#0.5
#echo "GPIO#08 = $zzumo" > /dev/console
if [ ! -e /sys/class/gpio/gpio8 ]; then
	echo 8 > /sys/class/gpio/export
	echo out > /sys/class/gpio/gpio8/direction
fi
echo $zzumo > /sys/class/gpio/gpio8/value



if [ ! -e /sys/class/gpio/gpio7 ]; then
	echo 7 > /sys/class/gpio/export
	echo out > /sys/class/gpio/gpio7/direction
fi
if [ $(( var & 0x1 )) -eq $((0x1)) ]; then
#	echo "GPIO#07 = 1" > /dev/console
	echo 1 > /sys/class/gpio/gpio7/value
else
#	echo "GPIO#07 = 0" > /dev/console
	echo 0 > /sys/class/gpio/gpio7/value
fi



if [ ! -e /sys/class/gpio/gpio9 ]; then
	echo 9 > /sys/class/gpio/export
	echo out > /sys/class/gpio/gpio9/direction
fi
if [[ $(( var & 0x2 )) -eq $((0x2)) ]]; then
#	echo "GPIO#09 = 1" > /dev/console
	echo 1 > /sys/class/gpio/gpio9/value
else
#	echo "GPIO#09 = 0" > /dev/console
	echo 0 > /sys/class/gpio/gpio9/value
fi



if [ ! -e /sys/class/gpio/gpio10 ]; then
	echo 10 > /sys/class/gpio/export
	echo out > /sys/class/gpio/gpio10/direction
fi
if [[ $(( var & 0x4 )) -eq $((0x4)) ]]; then
#	echo "GPIO#10 = 1" > /dev/console
	echo 1 > /sys/class/gpio/gpio10/value
else
#	echo "GPIO#10 = 0" > /dev/console
	echo 0 > /sys/class/gpio/gpio10/value
fi



if [ ! -e /sys/class/gpio/gpio12 ]; then
	echo 12 > /sys/class/gpio/export
	echo out > /sys/class/gpio/gpio12/direction
fi
if [[ $(( var & 0x8 )) -eq $((0x8)) ]]; then
#	echo "GPIO#12 = 1" > /dev/console
	echo 1 > /sys/class/gpio/gpio12/value
else
#	echo "GPIO#12 = 0" > /dev/console
	echo 0 > /sys/class/gpio/gpio12/value
fi



if [ ! -e /sys/class/gpio/gpio11 ]; then
	echo 11 > /sys/class/gpio/export
	echo out > /sys/class/gpio/gpio11/direction
fi
if [[ $(( var & 0x10 )) -eq $((0x10)) ]]; then
#	echo "GPIO#11 = 1" > /dev/console
	echo 1 > /sys/class/gpio/gpio11/value
else
#	echo "GPIO#11 = 0" > /dev/console
	echo 0 > /sys/class/gpio/gpio11/value
fi



# ATT_LE_1st/ATT_LE_2nd, latch enable needs minimum 30ns high clock
if [ ! -e /sys/class/gpio/gpio3 ]; then
	echo 3 > /sys/class/gpio/export
	echo out > /sys/class/gpio/gpio3/direction
fi

if [ ! -e /sys/class/gpio/gpio4 ]; then
	echo 4 > /sys/class/gpio/export
	echo out > /sys/class/gpio/gpio4/direction
fi
echo 1 > /sys/class/gpio/gpio3/value
echo 1 > /sys/class/gpio/gpio4/value
echo 0 > /sys/class/gpio/gpio3/value
echo 0 > /sys/class/gpio/gpio4/value



echo "1 and 0 latch GPIO-3 && GPIO-4" > /dev/console
