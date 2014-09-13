#!/usr/bin/bash

CLUSTERNAME=$( head -n 1 /opt/mapr/conf/mapr-clusters.conf|awk {'print $1'} )

NFSMOUNT=/mapr/${CLUSTERNAME}
TABLENAME="products"
TABLEPATH=${NFSMOUNT}/tables/${TABLENAME}

#first , delete if it exists

 if [ -L ${TABLEPATH} ]
 	then
 		echo "deleting existing table ${TABLEPATH}"
 		rm -f  ${TABLEPATH}
 fi

maprcli table create -path ${TABLEPATH} -defaultreadperm 'g:mapr | g:root' -defaultwriteperm 'g:mapr | g:root' -defaultappendperm 'g:mapr | g:root' 
maprcli table cf create -path ${TABLEPATH} -cfname details 
maprcli table cf create -path ${TABLEPATH} -cfname pricing 

/usr/bin/hadoop fs -chmod 777 ${TABLEPATH}

HBVERSION=$( cat /opt/mapr/hbase/hbaseversion )






export HBASE_HOME=/opt/mapr/hbase/hbase-${HBVERSION}
CLUSTERNAME=$( cat /opt/mapr/conf/mapr-clusters.conf |awk {'print $1'} )




#import

hadoop jar $HBASE_HOME/hbase-0.94.21-mapr-1407.jar \
        importtsv -Dimporttsv.separator=, \
        -Dimporttsv.columns=HBASE_ROW_KEY,details:name,details:category,pricing:price \
        ${TABLEPATH} \
        /mapr/${CLUSTERNAME}/drill-beta-demo/data/output/products/products.csv

