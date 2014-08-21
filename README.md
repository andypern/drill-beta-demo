#Drill demo on sandbox

##Intro


##Pre-reqs

* 3.1.1 sandbox (get from http://package.mapr.com/releases/v3.1.1/sandbox/)
* internet connectivity from sandbox to outside world


##Setup

To make life easier, we'll be using a github package to grab the dataset and to run some simple shell scripts to pull down drill and populate the data.


###Install packages

To start, ssh as root to your sandbox VM.

Install git:

	yum install -y git

Go to proper directory:

	cd /mapr/demo.mapr.com


Grab repo:

	git clone https://github.com/andypern/drill-beta-demo

Go to proper directory:

	cd drill-beta-demo

Run setup script:

	sh scripts/setup.sh

	
	


###configure storage-plugins

In the UI (http://ip:8047) , go to the Storage page, then create the following storage-plugins:



####MapRDB

	
	{
	  "type" : "hbase",
	  "enabled" : true,
	  "config" : {
	    "hbase.table.namespace.mappings" : "*:/tables"
	  }
	}


	
	
####MFS

	{
	  "type": "file",
	  "enabled": true,
	  "connection": "maprfs:///",
	  "workspaces": {
	    "root": {
	      "location": "/mapr/demo.mapr.com/data",
	      "writable": false,
	      "storageformat": null
	    },
	    "nested": {
	      "location": "/mapr/demo.mapr.com/data/nested",
	      "writable": true,
	      "storageformat": "parquet"
	    },
	    "flat": {
	      "location": "/mapr/demo.mapr.com/data/flat",
	      "writable": true,
	      "storageformat": "parquet"
	    },
	    "views": {
	      "location": "/mapr/demo.mapr.com/data/views",
	      "writable": true,
	      "storageformat": "parquet"
	    }
	  },
	  "formats": {
	    "psv": {
	      "type": "text",
	      "extensions": [
	        "tbl"
	      ],
	      "delimiter": "|"
	    },
	    "csv": {
	      "type": "text",
	      "extensions": [
	        "csv"
	      ],
	      "delimiter": ","
	    },
	    "tsv": {
	      "type": "text",
	      "extensions": [
	        "tsv"
	      ],
	      "delimiter": "\t"
	    },
	    "parquet": {
	      "type": "parquet"
	    },
	    "json": {
	      "type": "json"
	    }
	  }
	}
	
####HIVE

	{
	  "type": "hive",
	  "enabled": true,
	  "configProps": {
	    "hive.metastore.uris": "thrift://localhost:9083",
	    "hive.metastore.sasl.enabled": "false"
	  }
	}
	

##Sample queries


###SQLLine

The setup.sh script creates an alias, to make it easier to launch sqlline.  to verify if your queries are working:

	sqlline

At the sqlline prompt:

	0: jdbc:drill:> show databases;

You should see something like this:

	+-------------+
	| SCHEMA_NAME |
	+-------------+
	| hive.default |
	| hbase       |
	| sys         |
	| MFS.default |
	| MFS.nested  |
	| MFS.root    |
	| MFS.views   |
	| MFS.flat    |
	| INFORMATION_SCHEMA |
	| MAPRDB      |
	+-------------+

###HIVE

Switch to hive.default workspace:

	0: jdbc:drill:> use hive.`default`;

Verify tables exist:

	0: jdbc:drill:> show tables;
	+--------------+------------+
	| TABLE_SCHEMA | TABLE_NAME |
	+--------------+------------+
	| hive.default | orders     |
	| hive.default | customers  |
	+--------------+------------+
	2 rows selected (1.157 seconds)

Quick selects:

	select * from orders limit 10;
	select * from customers limit 10;


###MapR DB (NOSQL)

switch workspaces:
	
	0: jdbc:drill:> use maprdb;

Verify tables exist:

	0: jdbc:drill:> show tables;
	+--------------+------------+
	| TABLE_SCHEMA | TABLE_NAME |
	+--------------+------------+
	| hbase        | products   |
	+--------------+------------+
	1 row selected (0.437 seconds)
	
	
Quick query:

	select * from products limit 3;
	
You'll see something like this:

	+------------+------------+------------+
	|  row_key   |  details   |  pricing   |
	+------------+------------+------------+
	| [B@10188f19 | {"category":"bGFwdG9w","name":"IlNvbnkgbm90ZWJvb2si"} | {"price":"OTU5"} |
	| [B@3c5aba90 | {"category":"RW52ZWxvcGVz","name":"IzEwLTQgMS84IHggOSAxLzIgUHJlbWl1bSBEaWFnb25hbCBTZWFtIEVudmVsb3Blcw=="} | {"price":"MTY="} |
	| [B@688e62e4 | {"category":"U3RvcmFnZSAmIE9yZ2FuaXphdGlvbg==","name":"MjQgQ2FwYWNpdHkgTWF4aSBEYXRhIEJpbmRlciBSYWNrc1BlYXJs"} | {"price":"MjEx"} |
	+------------+------------+------------+
	3 rows selected (0.346 seconds)				


Not so useful?  Try casting:


	select cast (row_key as int) as prod_id, cast
	(t.details.name as varchar(20)) as name, cast
	(t.details.category as varchar(20)) as category, cast
	(t.pricing.price as varchar(20)) as price
	 from products t limit 3;
	 
That's better:

	+------------+------------+------------+------------+
	|  prod_id   |    name    |  category  |   price    |
	+------------+------------+------------+------------+
	| 0          | "Sony notebook" | laptop     | 959   |
	| 1          | #10-4 1/8 x 9 1/2 Pr | Envelopes  | 16     |
	| 10         | 24 Capacity Maxi Dat | Storage & Organizati | 211        |
	+------------+------------+------------+------------+
	3 rows selected (0.242 seconds)



###Filesystem queries:


First, something simple, from a flat (non-nested) JSON file:


	select * from mfs.flat.logs limit 10;

Directory-based selects:

	select * from mfs.flat.logs where dir0 = 2012 limit 10;

	select * from mfs.flat.logs where dir0 = 2012 and dir1 >=9 limit 10;

Nested JSON:

	select * from mfs.nested.clicks limit 10;

Now  you'll want to get access to the individual fields inside the JSON blobs:

	select t.trans_id,t.`date` as sess_date, t.user_info.cust_id as cust_id,t.user_info.device as device,
	t.trans_info.prod_id as prod_id, t.trans_info.purch_flag as purch_flag 
	from mfs.nested.clicks t limit 10

To get access into the array: 

	select t.trans_id,t.`date` as sess_date, t.user_info.cust_id as cust_id,t.user_info.device as device, t.trans_info.prod_id[0] as prod_id, t.trans_info.purch_flag as purch_flag from mfs.nested.clicks t where t.trans_info.prod_id[0] is not null limit 10;


###Creating views

By now you're noticing that it can be a little cumbersome to get direct access into the more complex data structures (MaprDB and nested JSON).  Especially when joining tables, its easier if you can use a more compact syntax. Creating a view is a simple way to deal with this, and drill provides a simple mechanism to do so.  If you'll note from when you configured the  `mfs` storage plugin, there was a workspace explicitly set aside for views to live in.

Here's how to create a view using one of the more complex queries from above:


First for MaprDB:

	create view mfs.views.productview as select cast (row_key as int) as prod_id, cast
	(t.details.name as varchar(20)) as name, cast
	(t.details.category as varchar(20)) as category, cast
	(t.pricing.price as varchar(20)) as price
	 from products t;
	 
	 
Here's how to 'view' all of your views:

	select * from INFORMATION_SCHEMA.`VIEWS`;
	


##TODO

### CSV

###ODBC / Drill explorer
