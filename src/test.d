
module commando.main;

import commando;


private void testAll(){
	auto commando = new Interpreter;
	commando.init([&loadEcho, &loadBuiltins]);
	commando.load("test/basic.cm");
	//commando.load("test/import.cm");
	commando.load("test/data.cm");
	commando.load("test/if.cm");
	commando.load("test/comparison.cm");
	//commando.load("test/classes.cm");
	commando.load("test/perf.cm");
	commando.load("test/pipes.cm");
	commando.load("test/fibonacci.cm");
	commando.load("test/capturing.cm");
}

/+
void main(){
	testAll;
}
+/

unittest {
	testAll;
}

