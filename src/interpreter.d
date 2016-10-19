
module pike.interpreter;

import pike;

alias FunctionReturn = Variable[]; 
alias Function = FunctionReturn delegate(Variable[], Context);


class Interpreter {

	Context[string] contexts;

    Statement[][string] loaded;

    this(){
		contexts["builtins"] = new Context("builtins", null);
    }

    void run(Context context, Statement statement){
		statement.run(this, context);
    }

	void run(Context context, Statement[] statements){
        foreach(s; statements)
            run(context, s);
	}

	void run(string path){
		if(path !in loaded)
			load(path);
		else
			run(contexts[path], loaded[path]);
	}

    void load(string path){
		assert(path != "builtins", `"builtins" is already in use`);
        if(path in loaded)
            return;
		auto context = new Context(path, null);
		context.imported ~= contexts["builtins"];
		contexts[path] = context;
        auto statements = parse(path, path.readText);
        loaded[path] = statements;
		try{
        	run(context, statements);
		}catch(PikeError e){
			writeln("Exception:");
			writeln(e.to!string);
			/+
			writeln("Context:");
			if(e.parentContext)
				writeln(e.parentContext.names);
			else
				writeln("No context");
			writeln(e.trace);
			+/
		}
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
