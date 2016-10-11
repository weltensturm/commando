
module pike.main;

import pike;



void main(){
	auto pike = new Interpreter;
	loadEcho(pike);
	loadBuiltins(pike);
	/+
	foreach(i; 1..200000){
		pike.run("test/basic.p");
		writeln(i);
	}
	+/
	pike.load("test/basic.p");
}
