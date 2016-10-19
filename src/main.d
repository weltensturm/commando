
module pike.main;

import pike;



void main(){
	auto pike = new Interpreter;
	loadEcho(pike);
	loadBuiltins(pike);
	pike.load("test/basic.p");
	pike.load("test/import.p");
	pike.load("test/tables.p");
	pike.load("test/if.p");
}
