
module commando.interpreter;

import commando;


class Interpreter {

	Stack base;
	Module[string] loaded;

	void init(void function(Stack)[] preload){
		base = new Stack;
		foreach(dg; preload)
			dg(base);
	}

	Module load(string path){
		if(path in loaded)
			return loaded[path];
		try {
			auto stack = base.dup;
			auto m = new Module(path);
			loaded[path] = m;
			m.parse;
			m.compileNames(stack);
			m.compile(stack);
			m.run(stack);
			return m;
		}catch(CommandoError e){
			writeln("Exception:");
			writeln(e.to!string);
			debug(Exception){
				void delegate(CommandoError) w;
				w = (CommandoError e){ writeln(e.trace); if(e.parent) w(e.parent.to!CommandoError); };
				w(e.to!CommandoError);
			}
			debug(Stack)
				printStack(e.context);	
			
		}
		return null;
	}

}


class Module {

	string path;
	string text;
	string[] names;
	Statement[] statements;

	this(string path){
		this.path = path;
	}

	void parse(){
		auto parser = new Parser(path);
		parser.parse(path.readText);
		statements = parser.statements;
	}

	void compileNames()(auto ref Stack stack){
		stack.prepush;
		names = statements.map!(s => s.names(stack)).join;
		foreach(a; names)
			stack.ensureIndex(a);
	}

	void compile()(auto ref Stack stack){
		foreach(s; statements)
			s.precompute(stack);
		names = stack.prepop;
		stack.precompute = false;
	}

	void run()(auto ref Stack stack){
		stack.push(names.length.to!int);
		foreach(s; statements)
			s.run(stack);
		stack.pop;
	}

}
