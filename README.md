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



####maprdb

	
	{
	  "type" : "hbase",
	  "enabled" : true,
	  "config" : {
	    "hbase.table.namespace.mappings" : "*:/tables"
	  }
	}


	
	
####dfs

		{
	  "type": "file",
	  "enabled": true,
	  "connection": "maprfs:///",
	  "workspaces": {
	    "root": {
	      "location": "/mapr/demo.mapr.com/data",
	      "writable": false,
	      "defaultInputFormat": null
	    },
	    "clicks": {
	      "location": "/mapr/demo.mapr.com/data/nested",
	      "writable": true,
	      "defaultInputFormat": null
	    },
	    "logs": {
	      "location": "/mapr/demo.mapr.com/data/flat",
	      "writable": true,
	      "defaultInputFormat": null
	    },
	    "views": {
	      "location": "/mapr/demo.mapr.com/data/views",
	      "writable": true,
	      "defaultInputFormat": null
	    },
	    "tmp": {
	      "location": "/tmp",
	      "writable": true,
	      "defaultInputFormat": null
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
	    },
	    "maprdb": {
	      "type": "maprdb"
	    }
	  }
	}
	
####hive

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
	| dfs.default |
	| dfs.logs    |
	| dfs.root    |
	| dfs.views   |
	| dfs.clicks  |
	| dfs.tmp     |
	| sys         |
	| maprdb      |
	| cp.default  |
	| INFORMATION_SCHEMA |
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
	+--------------+------------+
	1 rows selected (1.157 seconds)

Quick selects:

	select * from orders limit 10;


###MapR DB (NOSQL)

switch workspaces:
	
	0: jdbc:drill:> use maprdb;

Verify tables exist:

	0: jdbc:drill:> show tables;
	+--------------+------------+
	| TABLE_SCHEMA | TABLE_NAME |
	+--------------+------------+
	| maprdb       | embeddedclicks |
	| maprdb       | customers  |
	| maprdb       | products   |
	+--------------+------------+
	3 rows selected (0.555 seconds)
	
	
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


	select * from dfs.logs.logs limit 10;

Directory-based selects:

	select * from dfs.logs.logs where dir0 = 2012 limit 10;

	select * from dfs.logs.logs where dir0 = 2012 and dir1 >=9 limit 10;

Nested JSON:

	select * from dfs.clicks.clicks limit 10;

Now  you'll want to get access to the individual fields inside the JSON blobs:

	select t.trans_id,t.`date` as sess_date, 
	t.user_info.cust_id as cust_id,t.user_info.device as device,
	t.trans_info.prod_id as prod_id, t.trans_info.purch_flag as purch_flag 
	from dfs.clicks.clicks t limit 10

To get access into the array: 

	select t.trans_id,t.`date` as sess_date, 
	t.user_info.cust_id as cust_id,t.user_info.device as device, 
	t.trans_info.prod_id[0] as prod_id, t.trans_info.purch_flag as purch_flag 
	from dfs.clicks.clicks t 
	where t.trans_info.prod_id[0] is not null limit 10;


###Creating views

By now you're noticing that it can be a little cumbersome to get direct access into the more complex data structures (MaprDB and nested JSON).  Especially when joining tables, its easier if you can use a more compact syntax. Creating a view is a simple way to deal with this, and drill provides a simple mechanism to do so.  If you'll note from when you configured the  `dfs` storage plugin, there was a workspace explicitly set aside for views to live in.

Here's how to create a view using one of the more complex queries from above:


First for MaprDB:

	use maprdb;

Create the view:

	create or replace view dfs.views.productview as select cast (row_key as int) as prod_id, cast
	(t.details.name as varchar(20)) as name, cast
	(t.details.category as varchar(20)) as category, cast
	(t.pricing.price as varchar(20)) as price
	 from products t;
	 
Now for our nested JSON:

	
	create or replace view dfs.views.nestedclickview as select t.trans_id,t.`date` as sess_date, 
	t.user_info.cust_id as cust_id,t.user_info.device as device,
	t.trans_info.prod_id as prod_id, t.trans_info.purch_flag as purch_flag 
	from dfs.clicks.clicks t

	 
	 
Here's how to 'view' all of your views:

	select * from INFORMATION_SCHEMA.`VIEWS`;
	
Output:
		
		0: jdbc:drill:> select * from INFORMATION_SCHEMA.`VIEWS`;
		+---------------+--------------+------------+-----------------+
		| TABLE_CATALOG | TABLE_SCHEMA | TABLE_NAME | VIEW_DEFINITION |
		+---------------+--------------+------------+-----------------+
		| DRILL         | dfs.views    | productview | SELECT CAST(`row_key` AS INTEGER) AS `prod_id`, CAST(`t`.`details`['name'] AS VARCHAR(20)) AS `name`, CAST(`t`.`details`['category'] AS VARCHAR(20)) AS `category`, CAST(`t`.`pricing`['price'] AS VARCHAR(20)) AS `price`
		FROM `products` AS `t` |
		| DRILL         | dfs.views    | nestedclickview | SELECT `t`.`trans_id`, `t`.`date` AS `sess_date`, `t`.`user_info`['cust_id'] AS `cust_id`, `t`.`user_info`['device'] AS `device`, `t`.`trans_info`['prod_id'] AS `prod_id`, `t`.`trans_info`['purch_flag'] AS `purch_flag`
		FROM `dfs`.`clicks`.`clicks` AS `t` |
		+---------------+--------------+------------+-----------------+
		2 rows selected (0.155 seconds)
	
To test your views:

	select * from dfs.views.productview limit 3;

should look like:

	+------------+------------+------------+------------+
	|  prod_id   |    name    |  category  |   price    |
	+------------+------------+------------+------------+
	| 0          | "Sony notebook" | laptop     | 959        |
	| 1          | #10-4 1/8 x 9 1/2 Pr | Envelopes  | 16         |
	| 10         | 24 Capacity Maxi Dat | Storage & Organizati | 211        |
	+------------+------------+------------+------------+
	3 rows selected (0.28 seconds)

For nestedclickview :

	select * from dfs.views.nestedclickview limit 3;

Which yields:

	+------------+------------+------------+------------+------------+------------+
	|  trans_id  | sess_date  |  cust_id   |   device   |  prod_id   | purch_flag |
	+------------+------------+------------+------------+------------+------------+
	| 31920      | 2014-04-26 | 22526      | IOS5       | [174,2]    | false      |
	| 31026      | 2014-04-20 | 16368      | AOS4.2     | []         | false      |
	| 33848      | 2014-04-10 | 21449      | IOS6       | [582]      | false      |
	+------------+------------+------------+------------+------------+------------+
	3 rows selected (0.314 seconds)

###JOINs

Now that you have some views setup, test out a quick JOIN between your MaprDB table and your JSON 'table'.

To make things simple, switch workspaces:

	use dfs.views;

verify you see your views:

	0: jdbc:drill:> show tables;
	+--------------+------------+
	| TABLE_SCHEMA | TABLE_NAME |
	+--------------+------------+
	| mfs.views    | productview |
	| mfs.views    | nestedclickview |
	+--------------+------------+
	2 rows selected (0.24 seconds)

Here's a join:

	select n.trans_id, n.sess_date, n.device, p.name as product, p.category 
	from nestedclickview n, productview p 
	where n.prod_id[0] = p.prod_id limit 3;
	
Output:

	+------------+------------+------------+------------+------------+
	|  trans_id  | sess_date  |   device   |  product   |  category  |
	+------------+------------+------------+------------+------------+
	| 32359      | 2014-04-19 | IOS5       | "Sony notebook" | laptop     |
	| 30778      | 2014-04-13 | AOS4.2     | Acco PRESSTEX� Data  | Binders and Binder A |
	| 36131      | 2014-04-23 | IOS5       | #10 Self-Seal White  | Envelopes  |
	+------------+------------+------------+------------+------------+
	3 rows selected (1.356 seconds)

	
	


Pretty nifty.

###Arrays

####Repeated Count

You may have noticed that in our JSON queries we directly accessed the 'prod_id' array using an array index.  That's one example of how to handle dealing with arrays.  Another is to use the repeated_count function to allow you to count the # of elements in the array for a given record.  Here's an example:

	select t.trans_id,t.`date` as sess_date, 
	t.user_info.cust_id as cust_id,t.user_info.device as device,
	repeated_count(t.trans_info.prod_id) as prod_count, 
	t.trans_info.purch_flag as purch_flag 
	from dfs.clicks.clicks t 
	where repeated_count(t.trans_info.prod_id) > 2 limit 3;
	
Output:

	+------------+------------+------------+------------+------------+------------+
	|  trans_id  | sess_date  |  cust_id   |   device   | prod_count | purch_flag |
	+------------+------------+------------+------------+------------+------------+
	| 32359      | 2014-04-19 | 15360      | IOS5       | 13         | true       |
	| 32421      | 2014-04-15 | 23599      | IOS5       | 11         | false      |
	| 39447      | 2014-04-21 | 16122      | IOS6       | 18         | false      |
	+------------+------------+------------+------------+------------+------------+
	3 rows selected (0.27 seconds)
	
	
This can be useful to determine how many products your customers searched for when logged into your mobile application.  

here's another example, this time allowing us to only see those records where less than 10 products were searched for

	select t.trans_id,t.`date` as sess_date, 
	t.user_info.cust_id as cust_id,t.user_info.device as device,
	repeated_count(t.trans_info.prod_id) as prod_count, t.trans_info.purch_flag as purch_flag 
	from dfs.clicks.clicks t 
	where repeated_count(t.trans_info.prod_id) < 10 limit 3;

Output:


	+------------+------------+------------+------------+------------+------------+
	|  trans_id  | sess_date  |  cust_id   |   device   | prod_count | purch_flag |
	+------------+------------+------------+------------+------------+------------+
	| 31920      | 2014-04-26 | 22526      | IOS5       | 2          | false      |
	| 31026      | 2014-04-20 | 16368      | AOS4.2     | 0          | false      |
	| 33848      | 2014-04-10 | 21449      | IOS6       | 1          | false      |
	+------------+------------+------------+------------+------------+------------+
	3 rows selected (0.334 seconds)

Or maybe you want to order by the repeated_count?

	select t.trans_id,t.`date` as sess_date, 
	t.user_info.cust_id as cust_id,t.user_info.device as device,
	repeated_count(t.trans_info.prod_id) as prod_count, t.trans_info.purch_flag as purch_flag 
	from dfs.clicks.clicks t 
	where repeated_count(t.trans_info.prod_id)  > 0
	order by  repeated_count(t.trans_info.prod_id) desc limit 3;


Output:

	+------------+------------+------------+------------+------------+------------+
	|  trans_id  | sess_date  |  cust_id   |   device   | prod_count | purch_flag |
	+------------+------------+------------+------------+------------+------------+
	| 23718      | 2014-05-22 | 5598       | AOS4.4     | 45         | false      |
	| 15974      | 2014-04-14 | 1681       | IOS5       | 40         | false      |
	| 10701      | 2014-04-02 | 2105       | IOS7       | 39         | false      |
	+------------+------------+------------+------------+------------+------------+
	3 rows selected (4.429 seconds)

####Flatten
Ok great, you can use an array-index, and you can use repeated_count, but what if you want to do some aggregations and get each of the array elements to be usable in a query?  Flatten to the rescue!



	select t.trans_id,t.`date` as sess_date, 
	t.user_info.cust_id as cust_id,t.user_info.device as device,
	flatten(t.trans_info.prod_id) as prod_ids,
	t.trans_info.purch_flag as purch_flag 
	from dfs.clicks.clicks t limit 10;
	
Or here's the same query, in combination with repeated_count, to only show the transactions where the user selected more than 2 unique prod_id's :

	
	select t.trans_id,t.`date` as sess_date, t.user_info.cust_id as cust_id,t.user_info.device as device,
	flatten(t.trans_info.prod_id) as prod_ids,
	t.trans_info.purch_flag as purch_flag from dfs.clicks.clicks t 	where repeated_count(t.trans_info.prod_id) > 2 limit 30;
	
###JSON embedded in HBASE/MaprDB

But what if JSON lives inside MaprDB?  We've inserted some data into a MaprDB table, named `embeddedclicks`

First, switch to that db:

	use maprdb;

Now, lets look at one of the rows:

	select * from embeddedclicks limit 3;

which gives us;

		+------------+------------+
	|  row_key   |    blob    |
	+------------+------------+
	| [B@2be994d3 | {"json":"eyJ0cmFuc19pZCI6MTAwMDAsImRhdGUiOiIyMDE0LTA1LTE3IiwidGltZSI6IjAyOjI0OjU4IiwidXNlcl9pbmZvIjp7ImN1c3RfaWQiOjI4NDEsImRldmljZSI6IklPUzUiLCJzdGF0ZSI6InZhIn0sImFkX2luZm8iOnsiY2FtcF9pZCI6IjEifSwidHJhbnNfaW5mbyI6eyJwcm9kX2lkIjpbXSwicHVyY2hfZmxhZyI6InRydWUifX0="} |
	| [B@7429bf2a | {"json":"eyJ0cmFuc19pZCI6MTAwMDEsImRhdGUiOiIyMDE0LTA1LTIyIiwidGltZSI6IjE3OjUxOjE0IiwidXNlcl9pbmZvIjp7ImN1c3RfaWQiOjMyMjIsImRldmljZSI6IklPUzUiLCJzdGF0ZSI6ImZsIn0sImFkX2luZm8iOnsiY2FtcF9pZCI6IjEifSwidHJhbnNfaW5mbyI6eyJwcm9kX2lkIjpbNTEsNCwyLDEsMCwwLDQ3LDEsOSwxLDgzXSwicHVyY2hfZmxhZyI6ImZhbHNlIn19"} |
	| [B@4d001db8 | {"json":"eyJ0cmFuc19pZCI6MTAwMDMsImRhdGUiOiIyMDE0LTA1LTA1IiwidGltZSI6IjA4OjEzOjAwIiwidXNlcl9pbmZvIjp7ImN1c3RfaWQiOjM2MjUsImRldmljZSI6IklPUzYiLCJzdGF0ZSI6ImlhIn0sImFkX2luZm8iOnsiY2FtcF9pZCI6IjEifSwidHJhbnNfaW5mbyI6eyJwcm9kX2lkIjpbMCw3N10sInB1cmNoX2ZsYWciOiJmYWxzZSJ9fQ=="} |
	+------------+------------+
	3 rows selected (0.262 seconds)
	
	
not so useful.  lets cast to get things out:


	select cast (row_key as int) as mykey, cast (t.`blob`.json as varchar(600)) as
	jblob from embeddedclicks t limit 3;
	
this is a little better:

	+------------+------------+
	|   mykey    |   jblob    |
	+------------+------------+
	| 10000      | {"trans_id":10000,"date":"2014-05-17","time":"02:24:58","user_info":{"cust_id":2841,"device":"IOS5","state":"va"},"ad_info":{"camp_id":"1"},"trans_info":{"prod_id":[],"purch_flag":"true"}} |
	| 10001      | {"trans_id":10001,"date":"2014-05-22","time":"17:51:14","user_info":{"cust_id":3222,"device":"IOS5","state":"fl"},"ad_info":{"camp_id":"1"},"trans_info":{"prod_id":[51,4,2,1,0,0,47,1,9,1,83],"purch_flag":"false"}} |
	| 10003      | {"trans_id":10003,"date":"2014-05-05","time":"08:13:00","user_info":{"cust_id":3625,"device":"IOS6","state":"ia"},"ad_info":{"camp_id":"1"},"trans_info":{"prod_id":[0,77],"purch_flag":"false"}} |
	+------------+------------+
	3 rows selected (0.162 seconds)


Now that you can see the JSON, you need to use convert_from along with some subscripting to get it out:



	select foo.mycol.trans_id, foo.mycol.user_info.cust_id 
	from (select convert_from(cast (t.`blob`.json as varchar(600)),'JSON') as mycol 
	from embeddedclicks t) as foo limit 3;


much nicer:


	+------------+------------+
	|   EXPR$0   |   EXPR$1   |
	+------------+------------+
	| 10000      | 2841       |
	| 10001      | 3222       |
	| 10003      | 3625       |
	+------------+------------+
	3 rows selected (0.204 seconds)

Now a more useful query:

	select foo.mycol.trans_id as trans_id, 
	foo.mycol.user_info.cust_id as cust_id, 
	foo.mycol.user_info.device as device, 
	foo.mycol.user_info.state as state, 
	foo.mycol.trans_info.prod_id[0] as prod_id, 
	foo.mycol.trans_info.purch_flag as purch_flag  from 
	 (select convert_from(cast (t.`blob`.json as varchar(600)),'JSON') as mycol from embeddedclicks t) 
	 as foo limit 3;
 
 
 
 


##TODO

* kvgen function
* yelp data
*  twitter data
* 


### CSV

###ODBC / Drill explorer
