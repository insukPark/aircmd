#!/bin/sh

exportName=`date +%Y%m%d_%H%M%S`

#output HTTP header
echo "Pragma: no-cache\n"
echo "Cache-control: no-cache\n"
echo "Content-type: text/html"
echo "Content-Transfer-Encoding: binary"								#  "\n" make Un*x happy
echo "Content-Disposition: attachment; filename=\"vtlog-$exportName.txt\""
echo ""

logread
