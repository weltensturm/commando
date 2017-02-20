
module commando.interpreter;

import commando;

alias FunctionReturn = Variable[];
alias Function = FunctionReturn delegate(Parameter[], Variable);


auto nothing(){
	return FunctionReturn.init;
}


Variable context(Variable parent){
	auto context = new Variable(Variable.Type.table);
	context["__context"] = context;
	if(parent)
		context["__index"] = parent;
	context["__imported"] = new Variable(Variable.Type.table);
	return context;
}


void printTable(Variable variable, size_t level=0){
	foreach(k, v; variable){
		if(v.type == Variable.Type.table){
			if(v == variable)
				writeln(' '.repeat(level*4), k, " <-");
			else {
				writeln(' '.repeat(level*4), k, ":");
				printTable(v, level+1);
			}
		}else
			writeln(' '.repeat(level*4), k, " = ", v);
	}
}


class Interpreter {

	Variable global;

	Statement[][string] loaded;
	Variable[string] loadedContexts;

	this(){
		global = context(null);
		global["__global"] = global;
	}

	void run(Variable context, Statement statement){
		statement.run(context);
	}

	void run(Variable context, Statement[] statements){
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

	Variable load(string path){
		if(path in loadedContexts)
			return loadedContexts[path];
		auto context = .context(global);//new Context(path, global);
		//global["__imported"] ~= context;
		try{
			auto statements = parse(path, path.readText);
			loaded[path] = statements;
			loadedContexts[path] = context;
			run(context, statements);
		}catch(CommandoError e){
			writeln("Exception:");
			void delegate(CommandoError) w;
			w = (CommandoError e){ writeln(e.trace); if(e.parent) w(e.parent.to!CommandoError); };
			writeln(e.to!string);
			w(e.to!CommandoError);
			/+
			writeln("Context:");
			if(e.parentContext)
				writeln(e.parentContext.names);
			else
				writeln("No context");
			writeln(e.trace);
			+/
		}
		return context;
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
