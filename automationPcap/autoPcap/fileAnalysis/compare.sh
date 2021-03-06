#!/bin/bash
path="/root/git/testing/automationPcap/autoPcap/fileAnalysis"
networkIP=$2
pcapfile=$1
if [ $# -lt 2 ]
then
	echo "please compare.sh [pcapfile] [networkIP]"
	exit
else
	cd $path
fi
###############transfer pcap to traffic machine###############
sshpass -p "polydata" scp $pcapfile root@192.168.25.85:/root
#sshpass -p "polydata" ssh root@192.168.25.42 ./send_pcap.sh 10 $pcapfile em2 1
traffic()
{
expect ssh_exe_cmd.exp 192.168.25.85 root polydata "./send_pcap.sh $pcapfile 10 em2 1"
}

###############analysis pcap and get the total pkgs and length###############
total_get()
{
sh total_get.sh $pcapfile
}

###############search ES and get the total pkgs and length###############
flow_search()
{
scport=`tail -5 /tmp/11.log| grep PORT|awk -F'<' '{print $2}'|awk -F':' '{print $2}'`
dstport=`tail -5 /tmp/11.log| grep PORT|awk -F'<' '{print $1}'|awk -F':' '{print $2}'`
sh flow_searchToFile.sh $scport $dstport $networkIP
}

###############compare the pkgs and length between local and ES###############
compare()
{
echo "compare() $@"

if [ "$2" = "$3" ]; then
	echo "$1 [$2] is equal to $4 [$3]-------PASS"
else
	echo "$1 [$2] is not equal to $4 [$3]--------FAIL"
fi

}

traffic

sleep 60

total_get

flow_search

#assign value of necessary parameters
pcap_local="pkginfo_local.log"
data_ES="pkginfo_ES.log"
SendPkt=`cat $pcap_local|grep SendPkt|awk -F ': ' '{print $2}'`
SendLen=`cat $pcap_local|grep SendLen|awk -F ': ' '{print $2}'`
RecPkt=`cat $pcap_local|grep RecPkt|awk -F ': ' '{print $2}'`
Reclen=`cat $pcap_local|grep Reclen|awk -F ': ' '{print $2}'`

SendPkt_ES=`cat $data_ES|awk -F ',' '{print$1}'|awk -F ':' '{print$2}'`
SendLen_ES=`cat $data_ES|awk -F ',' '{print$4}'|awk -F ':' '{print$2}'`
RecPkt_ES=`cat $data_ES|awk -F ',' '{print$3}'|awk -F ':' '{print$2}'`
Reclen_ES=`cat $data_ES|awk -F ',' '{print$2}'|awk -F ':' '{print$2}'`


echo "=================================================================="
compare "SendPkt" "$SendPkt" "$SendPkt_ES" "SendPkt_ES"
compare "SendLen" $SendLen $SendLen_ES "SendLen_ES"
compare "RecPkt" $RecPkt $RecPkt_ES "RecPkt_ES"
compare "Reclen" $Reclen $Reclen_ES "Reclen_ES"
echo "=================================================================="
