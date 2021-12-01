#!/bin/sh

exportName=`date +%Y%m%d_%H%M%S`

filename=""
ext=""
filecnt=`ls /tmp/wpspkt* | wc -l`

if [ $filecnt -gt 1 ]; then
	files=`ls /tmp/wpspkt* | tr '\r\n' ' '`
	filename="/tmp/wpspkt.tar.gz"
	tar -cvzf $filename $files > /dev/null 2>&1
	ext="tar.gz"
else
	filename="/tmp/wpspkt0"
	if [ ! -f $filename ]; then
		exit 0
	fi
	ext="cap"
fi

#output HTTP header
echo "Pragma: no-cache\n"
echo "Cache-control: no-cache\n"
echo "Content-type: text/html"
echo "Content-Transfer-Encoding: binary"								#  "\n" make Un*x happy
echo "Content-Disposition: attachment; filename=\"vtpkt-$exportName.$ext\""
echo ""

cat $filename

if [ $filecnt -gt 1 ]; then
	rm -f $filename
fi
