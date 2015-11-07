/**
*
* CFMongoDB Coldbox Module Configuration
*
* Allows Coldbox to use cfmongodb library as a module and creates the CF mappings
*
* Note: This config file is designed for use with the CBMongoDB Module,
* to use this module directly see the ModuleConfig.cfc configure(),onLoad() and onUnload() methods at
* https://github.com/jclausen/cbmongodb
*
*
*
* @author Bill Shelton <bill@if.io>
* @author Marc Escher <marc.esher@gmail.com>
* @author Jon Clausen <jon_clausen@silowebworks.com>
*
* @link https://github.com/jclausen/cfmongodb [coldbox]
*/
component accessors=true{
	property name="wirebox" inject="wirebox";

	// Module Properties
	this.title 				= "CFMongoDB";
	this.author 			= "Jon Clausen";
	this.webURL 			= "https://github.com/jclausen/cfmongodb/tree/coldbox";
	this.description 		= "ColdFusion SDK to interact with MongoDB NoSQL Server";
	this.version			= "1.1.0.00074";
	// If true, looks for views in the parent first, if not found, then in the module. Else vice-versa
	this.viewParentLookup 	= true;
	// If true, looks for layouts in the parent first, if not found, then in module. Else vice-versa
	this.layoutParentLookup = true;
	// Module Entry Point
	this.entryPoint			= "cfmongodb";
	// Model Namespace to use
	this.modelNamespace		= "cfmongodb";
	// CF Mapping to register
	this.cfmapping			= "cfmongodb";
	// Module Dependencies to be loaded in order
	this.dependencies 		= [];

	/**
	* Fired on Module Registration
	*/
	function configure(){
		// Configure
		binder.map( "CFMongoJavaLoader" )
			.to("cfmongodb.core.JavaloaderFactory");

		this.configStruct = controller.getConfigSettings();
		// parse parent settings
		parseParentSettings();
			
		// Map Config
		binder.map( "MongoDBConfig" )
			.to( "cfmongodb.core.MongoConfig" )
			.initArg(name="MongoFactory",ref="CFMongoJavaLoader")
			.initArg(name="hosts",value=this.configStruct.MongoDB.hosts)
			.initArg(name="dbName",value=this.configStruct.MongoDB.db)
			.asSingleton();

		// Map our MongoDB Client using per-environment settings.
		binder.map( "MongoClient@cfMongoDB" )
			.to( "cfmongodb.core.MongoClient" )
			.initArg(name='MongoConfig',ref="MongoDBConfig")
			.asSingleton();
	}

	/**
	* Fired when the module is activated.
	*/
	function onLoad(){}


	/**
	* Prepare settings and returns true if using i18n else false.
	*/
	private function parseParentSettings(){
		var oConfig 		= controller.getSetting( "ColdBoxConfig" );
		var configStruct 	= controller.getConfigSettings();
		var MongoDB 		= oConfig.getPropertyMixin( "MongoDB", "variables", structnew() );

		//defaults
		this.configStruct.MongoDB = {
			hosts		= [
							{
								serverName='127.0.0.1',
								serverPort='27017'
							}
						  ],
			db 	= "local",
			viewTimeout	= "1000"
		};

		//Check for IOC Framework
		structAppend( this.configStruct.MongoDB, MongoDB, true );

	}
}