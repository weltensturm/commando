
module commando.main;

import commando;

void main(){}

unittest {
	auto commando = new Interpreter;
	loadEcho(commando);
	loadBuiltins(commando);
	commando.load("test/basic.cm");
	commando.load("test/import.cm");
	commando.load("test/tables.cm");
	commando.load("test/if.cm");
	commando.load("test/comparison.cm");
}
