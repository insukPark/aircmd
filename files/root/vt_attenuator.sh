#! /bin/sh

var=$1

echo "GPIO#06 = 0" > /dev/console
echo "GPIO#08 = 0" > /dev/console
if [ $(( var & 0x1 )) -eq $((0x1)) ]; then
#	echo 1=true > /dev/console
	echo "GPIO#07 = 1" > /dev/console
else
#	echo 1=false > /dev/console
	echo "GPIO#07 = 0" > /dev/console
fi

if [[ $(( var & 0x2 )) -eq $((0x2)) ]]; then
#	echo 2=true > /dev/console
	echo "GPIO#09 = 1" > /dev/console
else
#	echo 2=false > /dev/console
	echo "GPIO#09 = 0" > /dev/console
fi

if [[ $(( var & 0x4 )) -eq $((0x4)) ]]; then
#	echo 4=true > /dev/console
	echo "GPIO#10 = 1" > /dev/console
else
#	echo 4=false > /dev/console
	echo "GPIO#10 = 0" > /dev/console
fi

if [[ $(( var & 0x8 )) -eq $((0x8)) ]]; then
#	echo 8=true > /dev/console
	echo "GPIO#12 = 1" > /dev/console
else
#	echo 8=false > /dev/console
	echo "GPIO#12 = 0" > /dev/console
fi

if [[ $(( var & 0x10 )) -eq $((0x10)) ]]; then
#	echo 16=true > /dev/console
	echo "GPIO#11 = 1" > /dev/console
else
#	echo 16=false > /dev/console
	echo "GPIO#11 = 0" > /dev/console
fi

# ATT_LE_1st/ATT_LE_2nd, latch enable needs minimum 30ns high clock
echo "1 to set GPIO-3 && GPIO-4" > /dev/console
echo "0 to clear GPIO-3 && GPIO-4" > /dev/console

