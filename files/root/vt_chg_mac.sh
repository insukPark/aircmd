#!/bin/sh
#/root/vt_chg_mac.sh
FILE="/etc/fw_env.config"

if [ ! -e $FILE ];then
        echo "#dev-name offset    env-size" > /etc/fw_env.config
        echo "/dev/mtd1 0x30000 0x1000" >> /etc/fw_env.config
fi

fw_printenv | while IFS='=' read -r f1 eth
do
        if [ "$f1" == ethaddr ]; then
#               echo "PARKIS ethaddr=$eth" > /dev/console
#               echo "PARKIS ethaddr="$eth"" > /dev/console
#               echo "PARKIS ethaddr=${eth}" > /dev/console

                if [ ${#eth} != 17 ]; then
                        echo "PPPPPPPPPP: Wrong(${#eth}) ethaddr="$eth"" > /dev/console
                        exit
                fi

                sed -i "s/f8:5e:3c:12:d7:84/"$eth"/g" /etc/config/network
        elif [ "$f1" == wanaddr ]; then
                if [ ${#eth} != 17 ]; then
                        echo "PPPPPPPPPP: Wrong(${#eth}) wanaddr="$eth"" > /dev/console
                        exit
                fi

                sed -i "s/f8:5e:3c:12:d7:85/"$eth"/g" /etc/config/network
        elif [ "$f1" == wifi0addr ]; then
                if [[ -z "$(grep $eth /etc/config/wireless)" ]]; then
                        sed -i "/default_radio0/a option macaddr '$eth'" /etc/config/wireless
                fi
        elif [ "$f1" == wifi1addr ]; then
                if [[ -z "$(grep $eth /etc/config/wireless)" ]]; then
                        sed -i "/default_radio1/a option macaddr '$eth'" /etc/config/wireless
                fi
        fi
done

#echo "PARKIS confirm ethaddr=${eth}" > /dev/console

#if [ $eth == *"0" ]; then
#       exit
#fi
