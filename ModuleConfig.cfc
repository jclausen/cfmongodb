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
component{

	// Module Properties
	this.title 				= "CFMongoDB";
	this.author 			= "Jon Clausen";
	this.webURL 			= "http://https://github.com/jclausen/cfmongodb";
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
	function configure(){}

	/**
	* Fired when the module is activated.
	*/
	function onLoad(){}

	/**
	* Fired when the module is unloaded
	*/
	function onUnload(){}

}