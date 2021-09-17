#!/bin/sh
FILE="/etc/fw_env.config"
TMPFILE="/var/vttmp"

if [ ! -e $FILE ];then
	echo "#dev-name offset    env-size" > /etc/fw_env.config
	echo "/dev/mtd1 0x30000 0x1000" >> /etc/fw_env.config
fi

fw_printenv > $TMPFILE
while IFS='=' read -r f1 eth
do
	if [ "$f1" == ethaddr ]; then
		lanmac=$eth
	elif [ "$f1" == wanaddr ]; then
		wanmac=$eth
	elif [ "$f1" == ra0addr ]; then
		ra0mac=$eth
	elif [ "$f1" == ra1addr ]; then
		ra1mac=$eth
	fi
done < $TMPFILE

rm $TMPFILE

#check first boot after factory
if [[ ! -z "$(grep f8:5e:3c:12:d7:84 /etc/config/network)" ]]; then
	if [ ${#lanmac} != 17 ]; then
		echo "PPPPPPPPPP: Wrong(${#lanmac}) lanaddr="$lanmac"" > /dev/console
		lanmac="00:1A:56:99:99:96"
	fi
	sed -i "s/f8:5e:3c:12:d7:84/"$lanmac"/g" /etc/config/network

	if [ ${#wanmac} != 17 ]; then
		echo "PPPPPPPPPP: Wrong(${#wanmac}) wanaddr="$wanmac"" > /dev/console
		wanmac="00:1A:56:99:99:97"
	fi
	sed -i "s/f8:5e:3c:12:d7:85/"$wanmac"/g" /etc/config/network

	cp /root/wireless.conf /etc/config/wireless
	sed -i "s/00:1A:56:99:99:99/"$ra0mac"/g" /etc/config/wireless
	sed -i "s/00:1A:56:99:99:98/"$ra1mac"/g" /etc/config/wireless
fi

