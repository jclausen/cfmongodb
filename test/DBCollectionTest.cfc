<!---
NOTE: a number of these unit tests run ensureIndex(). This is because Marc likes to run mongo with --notablescan during development, and queries
against unindexed fields will fail, thus throwing off the tests.

You should absolutely NOT run an ensureIndex on your columns every time you run a query!

 --->
<cfcomponent output="false" extends="mxunit.framework.TestCase">
<cfscript>
import cfmongodb.core.*;


	javaloaderFactory = createObject('component','cfmongodb.core.JavaloaderFactory').init();
	mongoConfig = createObject('component','cfmongodb.core.MongoConfig').init(dbName="cfmongodb_tests", mongoFactory=javaloaderFactory);
	//mongoConfig = createObject('component','cfmongodb.core.MongoConfig').init(dbName="cfmongodb_tests");


	function setUp(){
		mongo = createObject('component','cfmongodb.core.Mongo').init(mongoConfig);
		col = 'people';
		dbCol = mongo.getDBCollection( col );

		atomicCol = 'atomictests';
		dbAtomicCol = mongo.getDBCollection( atomicCol );

		deleteCol = 'deletetests';
		dbDeleteCol = mongo.getDBCollection( deleteCol );
		commonSetUp();
	}

	function tearDown(){
		commonTearDown();
	}


	function getMongoDBCollection_should_return_underlying_java_DBCollection(){
		var jColl = dbCol.getMongoDBCollection();
		assertEquals("com.mongodb.DBApiLayer.mycollection",jColl.getClass().getCanonicalName());
	}

	/* !!!! Here begins CRUD Tests !!!!!*/

	/* !!!!  SAVE !!!! */

	function save_should_add_id_to_doc(){
	  var id = dbCol.save( doc );
	  assert( NOT isSimpleValue(id) );
	  dbCol.remove( doc );
	}

	function save_should_update_existing(){
		var id = dbCol.save( doc );

		doc.somethingnew = getTickCount();
		dbCol.save( doc );
		assertEquals( id, doc["_id"] );
	}

	function saveAll_should_return_immediately_if_no_docs_present(){
		assertEquals( [], dbCol.saveAll([]) );
	}

	function saveAll_should_save_ArrayOfDBObjects(){
		var i = 1;
		var people = [];
		var u = mongo.getMongoUtil();
		var purpose = "SaveAllDBObjectsTest";
		for( i = 1; i <= 2; i++ ){
			arrayAppend( people, u.toMongo( {"name"="unittest", "purpose"=purpose} ) );
		}
		dbCol.saveAll( people );
		var result = dbCol.query().$eq("purpose",purpose).count();
		assertEquals(2,result,"We inserted 2 pre-created BasicDBObjects with purpose #purpose# but only found #result#");
	}

	function saveAll_should_save_ArrayOfStructs(){
		var i = 1;
		var people = [];
		var purpose = "SaveAllStructsTest";
		for( i = 1; i <= 2; i++ ){
			arrayAppend( people, {"name"="unittest", "purpose"=purpose} );
		}
		dbCol.saveAll( people );
		var result = dbCol.query().$eq("purpose",purpose).count();
		assertEquals(2,result,"We inserted 2 structs with purpose #purpose# but only found #result#");
	}



	/* !!!! UPDATE !!!! */
	function update_should_replace_found_with_updated_doc(){
	  var originalCount = dbCol.query().$eq('name', 'bill' ).count();
	  var doc = {
	    'name'='jabber-walkie',
	    'address' =  {
	       'street'='456 boom boom',
	       'city'='anytowne',
	       'state'='??',
	       'country'='USA'
	    },
	    'favorite-foods'=['munchies']
	  };


	  dbCol.save(doc);
	  var results = dbCol.query().startsWith('name','jabber').find();

	  var replace_this = results.asArray()[1];
	  debug(replace_this);
	  replace_this['name'] = 'bill';
	  dbCol.update( replace_this );
	  results = dbCol.query().$eq('name', 'bill' ).find();
	  debug(results.asArray());
	  var finalSize = results.size();
	  var writeResult = dbCol.remove( replace_this );

	  assertEquals(originalCount+1, finalSize, "results should have been 1 but was #results.size()#" );
	}


	/* !!!!  FIND  !!!! */

	function search_should_honor_criteria(){
	  var initial = dbCol.query().startsWith('name','unittest').find().asArray();
	  //debug(initial);

	  var addNew = 5;
	  var people = createPeople( addNew, true );
	  var afterSave = dbCol.query().startsWith('name','unittest').find().asArray();

	  assertEquals( arrayLen(afterSave), arrayLen(initial) + addNew );
	}


	function search_sort_should_be_applied(){
		var people = createPeople(5, true);
		var asc = dbCol.query().$eq("name","unittest").find();
		var desc = dbCol.query().$eq("name","unittest").find(sort={"name"=-1});

		var ascResults = asc.asArray();
		var descResults = desc.asArray();
		debug( desc.getQuery().toString() );
		debug( desc.getSort().toString() );

		assertEquals( ascResults[1].age, descResults[ desc.size() ].age  );
	}

	function search_limit_should_be_applied(){
		var people = createPeople(5, true);
		var limit = 2;

		var full = dbCol.query().$eq("name","unittest").find();
		var limited = dbCol.query().$eq("name","unittest").find(limit=limit);
		assertEquals(limit, limited.size());
		assertTrue( full.size() GT limited.size() );
	}

	function search_skip_should_be_applied(){
		var people = createPeople(5, true);
		var skip = 1;
		var full = dbCol.query().$eq("name","unittest").find();
		var skipped = dbCol.query().$eq("name","unittest").find(skip=skip);

		assertEquals(full.asArray()[2] , skipped.asArray()[1], "lemme splain, Lucy: since we're skipping 1, then the first element of skipped should be the second element of full" );
	}

	function findById_should_return_doc_for_id(){
		var id = dbCol.save( doc );

		var fetched = dbCol.findById( id.toString() );
		assertEquals(id, fetched._id.toString());
	}

	function find_should_be_equivalent_to_search(){
		var people = createPeople(5, true);
		var fullViaQuery = dbCol.query(col).$eq("name","unittest").find();
		var fullViaFind = dbCol.find( {"name"="unittest"} );
		assertEquals( arrayLen(fullViaQuery.asArray()), arrayLen(fullViaFind.asArray()) );
	}

	function find_should_handle_datatypes_correctly(){
		var people = createPeople(5, true);
		var one = dbCol.find( {"counter"=3} );
		debug(one);
		assertEquals(1, one.size());
		var doc = one.asArray()[1];
		assertEquals( 3, doc.counter );
	}

	function findOne_should_return_first_found_document(){
		var people = createPeople(1, true);
		var one = dbcol.findOne({"name" = "unittest"});
		assertEquals( "unittest", one.name );
	}

	function findAndModify_should_atomically_update_and_return_new(){
		var collection = "atomictests";
		var dbAtomicCol = mongo.getDBCollection(collection);
		var count = 5;
		var people = createPeople(count=count, save="false");
		dbAtomicCol.ensureIndex(["INPROCESS"]);
		dbAtomicCol.saveAll(people);

		flush();

		//get total inprocess count
		var inprocess = dbAtomicCol.query().$eq("INPROCESS",false).find().size();

		//guard
		assertEquals(count, arrayLen(people));
		var query = {inprocess=false};
		var update = {inprocess=true, started=now(),owner=cgi.SERVER_NAME};
		var new = dbAtomicCol.findAndModify(query=query, update=update);
		flush();

		assertTrue( structKeyExists(new, "age") );
		assertTrue( structKeyExists(new, "name") );
		assertTrue( structKeyExists(new, "now") );
		assertTrue( structKeyExists(new, "started") );
		assertEquals( true, new.inprocess );
		assertEquals( cgi.SERVER_NAME, new.owner );

		var newinprocess = dbAtomicCol.query().$eq("INPROCESS",false).find();

		assertEquals(inprocess-1, newinprocess.size());
	}

	function group_should_honor_optional_command_parameters(){
		var collection = "groups";
		var dbGroupsCol = mongo.getDBCollection(collection);
		dbGroupsCol.remove({});

		dbGroupsCol.ensureIndex(fields=["ACTIVE"]);

		var groups = [
			{STATUS="P", ACTIVE=1, ADDED=now()},
			{STATUS="P", ACTIVE=1, ADDED=now()},
			{STATUS="P", ACTIVE=0, ADDED=now()},
			{STATUS="R", ACTIVE=1, ADDED=now()},
			{STATUS="R", ACTIVE=1, ADDED=now()}
		];
		dbGroupsCol.saveAll( groups );
		var groupResult = dbGroupsCol.group( "STATUS", {TOTAL=0}, "function(obj,agg){ agg.TOTAL++; }"  );

		assertEquals( arrayLen(groups), groupResult[1].TOTAL + groupResult[2].TOTAL, "Without any query criteria, total number of results for status should match total number of documents in collection" );

		//add a criteria query
		var groupResult = dbGroupsCol.group( "STATUS", {TOTAL=0}, "function(obj,agg){ agg.TOTAL++; }", {ACTIVE=1}  );
		assertEquals( arrayLen(groups)-1, groupResult[1].TOTAL + groupResult[2].TOTAL, "Looking at only ACTIVE=1 documents, total number of results for status should match total number of 'ACTIVE' documents in collection" );

		//add a finalize function
		groupResult = dbGroupsCol.group( keys="STATUS", initial={TOTAL=0}, reduce="function(obj,agg){ agg.TOTAL++; }", finalize="function(out){ out.HI='mom'; }"  );
		assertTrue( structKeyExists(groupResult[1], "HI"), "output group should have contained the key added by finalize but did not" );

		//use the keyf function to create a composite key
		groupResult = dbGroupsCol.group( keys="", initial={TOTAL=0}, reduce="function(obj,agg){ agg.TOTAL++; }", keyf="function(doc){ return {'TASK_STATUS' : doc.STATUS }; }"  );
		debug(groupResult);

		//TODO: get a better example of keyf
		assertTrue( structKeyExists(groupResult[1], "TASK_STATUS"), "Key should have been TASK_STATUS since we override the key in keyf function" );
	}
	function distinct_should_return_array_of_distinct_values(){
		var collection = "distincts";
		var dbDistinctCol = mongo.getDBCollection(collection);
		var all = [
			{val=1},
			{val=1},
			{val=2},
			{val=1},
			{val=100}
		];
		dbDistinctCol.remove({});
		var initial = dbDistinctCol.distinct("VAL");
		assertEquals(0,arrayLen(initial));

		dbDistinctCol.saveAll( all );
		var distincts = dbDistinctCol.distinct("VAL");
		assertEquals(1, distincts[1]);
		assertEquals(2, distincts[2]);
		assertEquals(100, distincts[3]);
	}


	function count_should_consider_query(){
		createPeople(2, true, "not unit test");

		dbCol.ensureIndex(["nowaythiscolumnexists"]);
		var allresults = dbCol.query().find();
		//debug(allresults.size());
		var all = dbCol.query().count();
		assertTrue( all GT 0 );

		var none = dbCol.query().$eq("nowaythiscolumnexists", "I'm no tree... I am an Ent!").count();
		//debug(none);
		assertEquals( 0, none );

		var people = createPeople(2, true);

		var some = dbCol.query().$eq("name", "unittest").count();
		all = dbCol.query().count();
		assertTrue( some GTE 2 );
		assertTrue( some LT all, "Some [#some#] should have been less than all [#all#]");

		var one = dbCol.count({"name"="unittest", "counter"=2}, "Since all unit test people are deleted before each test, there should only be a single unit test person with counter of 2 since we created 2 in this test");
		assertEquals( 1, one );
	}


	/* !!!! DELETE !!!! */

	function delete_should_delete_document_with_id(){
	  dbDeleteCol.drop();
	  dbDeleteCol.ensureIndex(["somenumber"]);
	  dbDeleteCol.ensureIndex(["name"]);
	  var doc = {
	    'name'='delete me',
		'somenumber' = 1,
	    'address' =  {
	       'street'='123 bye bye ln',
	       'city'='where-ever',
	       'state'='??',
	       'country'='USA'
	    }
	  };

	  doc['_id'] = dbDeleteCol.save( doc );

	  results = dbDeletecol.query().$eq('somenumber',1).find();

	  var writeResult = dbDeleteCol.remove( doc );
	  results = dbDeletecol.query().$eq('name','delete me').find();
	  assertEquals( 0, results.size() );
	}

	/* !!!! INDEXES !!!! */

	function getIndexes_should_return_indexes_for_collection(){
		var result = dbCol.dropIndexes();
		//guard
		assertEquals( 1, arrayLen(result), "always an index on _id" );

		dbCol.ensureIndex(fields=["name"]);
		dbCol.ensureIndex(fields=[{"name"=1},{"address.state"=-1}]);
		result = dbCol.getIndexes();

		assertTrue( arrayLen(result) GT 1, "Should be at least 2: 1 for the _id, and one for the index we just added");
	}

	private function getIndexesFailOverride(){
		throw("authentication failed");
	}


	private function flush(){
		//forces mongo to flush
		mongo.getMongoDB().getLastError();
	}
 </cfscript>

 <!--- include these here so they don't mess up the line numbering --->
 <cfinclude template="commonTestMixins.cfm">

</cfcomponent>
