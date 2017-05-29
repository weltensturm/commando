
module commando.interpreter;

import commando;

alias FunctionReturn = Variable[];
alias Function = FunctionReturn delegate(Parameter[], Stack);

auto nothing(){
	return [Variable()];
}


Variable context(){
	auto context = Variable(Variable.Type.data);
	context["__context"] = context;
	context["__imported"] = Variable(Variable.Type.data);
	return context;
}


Variable context(Variable parent){
	auto context = .context;
	context["__index"] = parent;
	return context;
}


void printData(Variable variable, size_t level=1, Variable[] datas=(Variable[]).init){
	if(level == 1)
		writeln("[");
	foreach(k, v; variable){
		if(v.type == Variable.Type.data){
			if(v == variable)
				writeln("|   ".repeat(level).join, k, " = this");
			else {
				writeln("|   ".repeat(level).join, k, ": ", variable);
				if(!datas.canFind(v))
					printData(v, level+1, datas ~= v);
			}
		}else
			writeln("|   ".repeat(level).join, k, " = ", v);
	}
	if(level == 1)
		writeln("]");
}

void printStack(Stack stack){
	writeln("Stack:");
	foreach(idx, n; stack.names)
		writeln("%s   %s = %s".format(idx, n, stack.stack[idx]));
}



class Interpreter {

	Stack base;
	Statement[][string] loaded;
	Stack[string] loadedContexts;

	void init(void function(Stack)[] preload){
		base = new Stack;
		base.push([]);
		foreach(dg; preload)
			dg(base);
	}

	void run(Stack context, Statement statement){
		statement.run(context);
	}

	void run(Stack context, Statement[] statements){
		foreach(s; statements)
			run(context, s);
	}

	void run(string path){
		if(path !in loaded)
			load(path);
		/+
		else
			run(global["__imported"][path], loaded[path]);
		+/
	}

	Stack load(string path){
		if(path in loadedContexts)
			return loadedContexts[path];
		auto stack = base.dup;
		try{
			auto statements = parse(path, path.readText);
			loaded[path] = statements;
			loadedContexts[path] = stack;
			stack.prepush;
			foreach(a; statements.map!(s => s.names(stack)).join)
				stack.ensureIndex(a);
			foreach(s; statements)
				s.precompute(stack);
			auto names = stack.prepop;
			stack.precompute = false;
			stack.push(names);
			run(stack, statements);
			stack.pop;
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
		return stack;
	}

	private Statement[][string] parsed;

	Statement[] parse(string identifier, string text){
		auto statements = parsed.get(text, []);
		if(!statements.length){
			auto parser = new Parser(identifier);
			parser.parse(text);
			statements = parser.statements;
			parsed[text] = statements;
		}
		return statements;
	}

}


auto iter(alias dg, T)(T start){
	struct Iter {
		T current;
		bool empty(){ return current is null; }
		void popFront(){ current = dg(current).to!T; }
		T front(){ return current; }
	}
	return Iter(start);
}