#!/usr/bin/bash

HBVERSION=$( cat /opt/mapr/hbase/hbaseversion )




export HBASE_HOME=/opt/mapr/hbase/hbase-${HBVERSION}
CLUSTERNAME=$( head -n 1 /opt/mapr/conf/mapr-clusters.conf|awk {'print $1'} )
NFSMOUNT=/mapr/${CLUSTERNAME}
TABLENAME="customers"
TABLEPATH=${NFSMOUNT}/tables/${TABLENAME}

#first delete table via hbase shell
echo 'disable '"'${TABLEPATH}'"'' | hbase shell

echo 'drop '"'${TABLEPATH}'"'' | hbase shell

#create table + 2 CF's
#echo 'create '"'${TABLEPATH}'"',"personal","address","loyalty"' | hbase shell

maprcli table create -path ${TABLEPATH} -defaultreadperm 'g:mapr | g:root' -defaultwriteperm 'g:mapr | g:root' -defaultappendperm 'g:mapr | g:root'
maprcli table cf create -path ${TABLEPATH} -cfname personal
maprcli table cf create -path ${TABLEPATH} -cfname address
maprcli table cf create -path ${TABLEPATH} -cfname loyalty

/usr/bin/hadoop fs -chmod 777 ${TABLEPATH}

#import

#hadoop jar $HBASE_HOME/hbase-0.94.21-mapr-1407.jar \
hbase org.apache.hadoop.hbase.mapreduce.ImportTsv -Dimporttsv.separator=, \
        -Dimporttsv.columns=HBASE_ROW_KEY,personal:name,address:state,personal:gender,personal:age,loyalty:agg_rev,loyalty:membership\
        ${TABLEPATH} \
        /mapr/${CLUSTERNAME}/drill-beta-demo/data/output/customers.all.csv
