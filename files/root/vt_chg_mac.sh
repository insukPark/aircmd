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
	echo "PARKIS: /root/vt_chg_mac.sh change mac..." > /dev/console
#	grep f8:5e:3c:12:d7:84 /etc/config/network > /dev/console
	sed -i "s/192.168.1.1/192.168.11.1/g" /etc/config/network
	[ -z "$(grep "option sequential_ip" /etc/config/dhcp)" ] && \
		sed -i "/config dnsmasq/a \	option sequential_ip '1'" /etc/config/dhcp

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

	[ -z "$(grep VX2000-2G-${lanmac:15:2} /root/wireless.conf)" ] && \
		sed -i "s/VX2000-2G/VX2000-2G-${lanmac:15:2}/g" /root/wireless.conf
	[ -z "$(grep VX2000-5G-${lanmac:15:2} /root/wireless.conf)" ] && \
		sed -i "s/VX2000-5G/VX2000-5G-${lanmac:15:2}/g" /root/wireless.conf
	cp /root/wireless.conf /etc/config/wireless
	[ ${#ra0mac} == 17 ] && sed -i "s/00:1A:56:99:99:99/"$ra0mac"/g" /etc/config/wireless
	[ ${#ra1mac} == 17 ] && sed -i "s/00:1A:56:99:99:98/"$ra1mac"/g" /etc/config/wireless

	# check 2.4G/5G selection slide switch
#	sed -i "/htmode/a \	option disabled '1'" /etc/config/wireless
#	sed -i "/encryption/a \	option disabled '1'" /etc/config/wireless
	# read GPIO 17
#	if [ -e /root/2g-switch ]; then
#		echo "2.4G, control GPIO 5" > /dev/console
#		sed -i "/wifi-device 'radio0'/,/wifi-device 'radio1'/{/option disabled/d}" /etc/config/wireless
#	else
#		echo "5G, control GPIO 5" > /dev/console
#		sed -i "/wifi-device 'radio1'/,$ {/option disabled/d}" /etc/config/wireless
#	fi

	# change ntp server
	sed -i "s/1.openwrt.pool.ntp.org/1.kr.pool.ntp.org/g" /etc/config/system
	sed -i "s/2.openwrt.pool.ntp.org/2.asia.pool.ntp.org/g" /etc/config/system
	sed -i "s/3.openwrt.pool.ntp.org/3.time.google.com/g" /etc/config/system
elif [ ${#lanmac} == 17 ] &&  [ -z "$(grep "$lanmac" /etc/config/network)" ]; then
	grep "option macaddr" /etc/config/network > $TMPFILE

	firstLine=1
	while read line
	do
		if [ $firstLine == 1 ]; then
			sed -i "s/$line/option macaddr '$lanmac'/g" /etc/config/network
			let firstLine=firstLine+1
		elif [ ${#wanmac} == 17 ]; then
			sed -i "s/$line/option macaddr '$wanmac'/g" /etc/config/network
		fi
	done < $TMPFILE

	rm $TMPFILE
elif [ ${#wanmac} == 17 ] &&  [ -z "$(grep "$wanmac" /etc/config/network)" ]; then
	grep "option macaddr" /etc/config/network > $TMPFILE

	firstLine=1
	while read line
	do
		if [ $firstLine == 1 ]; then
			let firstLine=firstLine+1
		else
			sed -i "s/$line/option macaddr '$wanmac'/g" /etc/config/network
		fi
	done < $TMPFILE

	rm $TMPFILE
fi

if [ ${#ra0mac} == 17 ] &&  [ -z "$(grep "$ra0mac" /etc/config/wireless)" ]; then
	grep "option macaddr" /etc/config/wireless > $TMPFILE

	firstLine=1
	while read line
	do
		if [ $firstLine == 1 ]; then
			sed -i "s/$line/option macaddr '$ra0mac'/g" /etc/config/wireless
			let firstLine=firstLine+1
		elif [ ${#ra1mac} == 17 ]; then
			sed -i "s/$line/option macaddr '$ra1mac'/g" /etc/config/wireless
		fi
	done < $TMPFILE

	rm $TMPFILE
elif [ ${#ra1mac} == 17 ] &&  [ -z "$(grep "$ra1mac" /etc/config/wireless)" ]; then
	grep "option macaddr" /etc/config/wireless > $TMPFILE

	firstLine=1
	while read line
	do
		if [ $firstLine == 1 ]; then
			let firstLine=firstLine+1
		else
			sed -i "s/$line/option macaddr '$ra1mac'/g" /etc/config/wireless
		fi
	done < $TMPFILE

	rm $TMPFILE
fi

# check 2.4G/5G selection slide switch
if [ -e /root/config/wifi-disable ]; then
	return 0
fi

sed -i "/option disabled '1'/d" /etc/config/wireless
sed -i "/htmode/a \	option disabled '1'" /etc/config/wireless
sed -i "/encryption/a \	option disabled '1'" /etc/config/wireless
# read GPIO 17, maybe low means 2G && high means 5G
if [ -e /root/2g-switch ]; then
	echo "2.4G, control GPIO 5 to low" > /dev/console
	sed -i "/wifi-device 'radio0'/,/wifi-device 'radio1'/{/option disabled/d}" /etc/config/wireless
else
	echo "5G, control GPIO 5 to high" > /dev/console
	sed -i "/wifi-device 'radio1'/,$ {/option disabled/d}" /etc/config/wireless
fi

# control attenuator /root/config/rf-att-strength
echo "PARKIS: need to set attenuation value" > /dev/console

