#!/usr/bin/bash

HBVERSION=$( cat /opt/mapr/hbase/hbaseversion )




export HBASE_HOME=/opt/mapr/hbase/hbase-${HBVERSION}
CLUSTERNAME=$( cat /opt/mapr/conf/mapr-clusters.conf |awk {'print $1'} )
TABLENAME="products"

#first delete table via hbase shell
echo 'disable '"'${TABLENAME}'"'' | hbase shell

echo 'drop '"'${TABLENAME}'"'' | hbase shell

#create table + 2 CF's
echo 'create '"'${TABLENAME}'"',"details","pricing"' | hbase shell

#import

hadoop jar $HBASE_HOME/hbase-0.94.17-mapr-1405.jar \
        importtsv -Dimporttsv.separator=, \
        -Dimporttsv.columns=HBASE_ROW_KEY,details:name,details:category,pricing:price \
        ${TABLENAME} \
        /mapr/${CLUSTERNAME}/drill-beta-demo/data/output/products/products.csv

