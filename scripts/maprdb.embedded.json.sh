#!/usr/bin/bash

CLUSTERNAME=$( head -n 1 /opt/mapr/conf/mapr-clusters.conf|awk {'print $1'} )

NFSMOUNT=/mapr/${CLUSTERNAME}
TABLENAME="embeddedclicks"
TABLEPATH=${NFSMOUNT}/tables/${TABLENAME}

#first , delete if it exists

 if [ -L ${TABLEPATH} ]
 	then
 		echo "deleting existing table ${TABLEPATH}"
 		rm -f  ${TABLEPATH}
 fi

maprcli table create -path ${TABLEPATH} -defaultreadperm 'g:mapr | g:root' -defaultwriteperm 'g:mapr | g:root' -defaultappendperm 'g:mapr | g:root' 
maprcli table cf create -path ${TABLEPATH} -cfname blob 

/usr/bin/hadoop fs -chmod 777 ${TABLEPATH}

HBVERSION=$( cat /opt/mapr/hbase/hbaseversion )



#import



cat /mapr/${CLUSTERNAME}/drill-beta-demo/scripts/embedded.input.txt | /usr/bin/hbase shell


