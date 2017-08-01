
module commando.parameter;

import commando;


class Parameter {
	Variable get(Stack){ assert(0); }
	void collect(Stack, void delegate(Variable), void delegate(string, Variable)){
		throw new CommandoError("Can only collect stack variable");
	}
	void set(Stack, Variable){ assert(0); }
	void precompute(Stack){ assert(0, "Cannot precompute " ~ typeid(this).to!string); }
	string[] names(Stack){ return []; }
	bool isNumber(){ return false; }
	string statement;
}


class ParameterLiteral: Parameter {

	Variable variable;
	bool type;

	this(double literal){
		variable = Variable(literal);
		type = true;
		statement = literal.to!string;
	}

	this(string literal){
		variable = Variable(literal);
		statement = "\"" ~ literal ~ "\"";
	}

	override Variable get(Stack stack){
		return variable;
	}

	override void set(Stack stack, Variable var){
		throw new CommandoError("Cannot assign to non-variable");
	}

	override void precompute(Stack stack){
	}

	override bool isNumber(){
		return type;
	}

}


class ParameterVariable: Parameter {

	string name;
	Stack.Pos stackIndex;

	this(string name){
		statement = name;
		this.name = name;
	}

	override Variable get(Stack stack){
		return stack[stackIndex];
	}

	override void set(Stack stack, Variable var){
		stack[stackIndex] = var;
	}

	override void precompute(Stack stack){
		stackIndex = stack.getIndex(name);
	}

}


class ParameterDynamic: Parameter {

	Variable variable;

	this(){}

	this(Variable variable){
		this.variable = variable;
	}

	override Variable get(Stack stack){
		return variable;
	}

}


class ParameterCall: Parameter {

	Statement[] statements;

	string identifier;
	long line;

	this(string statement, string identifier, long line){
		this.statement = statement;
		this.identifier = identifier;
		this.line = line;
		auto parser = new Parser(identifier, line);
		parser.parse(statement);
		statements = parser.statements;
	}

	override Variable get(Stack stack){
		debug(Parameter){
			writeln("CALL \"", statement, "\"");
		}
		return run(statements, stack, true);
	}

	override void set(Stack, Variable){
		throw new CommandoError("Cannot assign to non-variable");
	}

	override void precompute(Stack stack){
		foreach(s; statements){
			s.precompute(stack);
		}
	}

	override string[] names(Stack stack){
		return statements.map!(a => a.names(stack)).join;
	}

}


class ParameterData: Parameter {

	Statement[] statements;

	string identifier;

	this(string statement, string identifier, long line){
		this.statement = statement;
		this.identifier = identifier;

		auto block = new ParameterFunction(true, [], statement, identifier, line);
		auto call = new ParameterVariable("data");
		statements ~= new Statement([call, block], identifier, line, statement);
	}

	override Variable get(Stack stack){
		debug(Parameter){
			writeln("DATA ", statement);
		}
		return run(statements, stack, true);
	}

	override void set(Stack context, Variable var){
		throw new Exception("Cannot assign to non-variable");
	}

	override void precompute(Stack stack){
		foreach(s; statements)
			s.precompute(stack);
	}

}


class ParameterFunction: Parameter {

	Statement[] statements;
	string identifier;
	bool isFunction;

	string[] names;
	Stack.Pos[] argTargets;
	Stack.Pos[] blockTargets;
	Variable[] parameterCache;

	this(bool isFunction, string[] names, string block, string identifier, long line){
		this.statement = block;
		this.identifier = identifier;
		this.names = names;
		this.isFunction = isFunction;
		auto parser = new Parser(identifier, line);
		parser.parse(block);
		statements = parser.statements;
	}

	override Variable get(Stack stack){
        return Variable((Parameter[] params, Stack caller){
			debug(Parameter){
				writeln("CALL ", isFunction ? "FN " : "BLOCK ", names, " \"", statement, "\"");
			}
			checkLength(argTargets.length, params.length);
			foreach(i, ref v; parameterCache)
				v = params[i].get(caller);
        	stack.push(parameterCache, (names.length-argTargets.length).to!int);
            auto r = run(statements, stack, isFunction);
            stack.pop;
            return r;
        });
	}

	override void collect(Stack stack, void delegate(Variable) unnamed, void delegate(string, Variable) named){
		debug(Parameter){
			writeln("COLLECT ", isFunction ? "FN " : "BLOCK ", names, " \"", statement, "\"");
		}
		if(argTargets.length)
			throw new CommandoError("Cannot collect parametrized function (for now)");
		stack.push(names.length.to!int);
		foreach(statement; statements){
			auto r = statement.run(stack);
			if(r)
				unnamed(r);
			if(checkReturn(false))
				break;
		}
		foreach(i; argTargets.length..names.length)
			named(names[i], stack[blockTargets[i]]);
		stack.pop;
	}

	override void set(Stack context, Variable var){
		throw new Exception("Cannot assign to non-variable");
	}

	override void precompute(Stack stack){
		stack.prepush;
		foreach(a; names)
			argTargets ~= stack.register(a);
		foreach(a; statements.map!(s => s.names(stack)).join)
			stack.ensureIndex(a);
		foreach(s; statements)
			s.precompute(stack);
		stack.currentNames((names, indices){
			foreach(i; argTargets.length..names.length){
				blockTargets ~= indices[i];
			}
		});
		auto names = stack.prepop;
		assert(names.startsWith(this.names), "!%s.startsWith(%s)".format(this.names, names));
		this.names = names;
		parameterCache.length = argTargets.length;
	}

}


class ParameterAssignmentTarget: ParameterVariable {
	
	this(string name){
		super(name);
	}

	override void precompute(Stack stack){
		stackIndex = stack.ensureIndex(name);
	}
	
	override string[] names(Stack stack){
		return [name];
	}
}


class ParameterIndexCall: Parameter {
	
	Parameter[3] parameters;

	string identifier;
	long line;
	double number;

	this(string statement, string identifier, long line){
		this.statement = statement;
		this.identifier = identifier;
		this.line = line;
		auto parser = new Parser(identifier, line);
		parser.parse(statement);
		assert(parser.statements.length == 1 && parser.statements[0].parameters.length == 3);
		parameters[0] = parser.statements[0].parameters[1];
		if(auto left = cast(ParameterLiteral)parameters[0]){
			auto right = parser.statements[0].parameters[2].to!ParameterLiteral.variable.number;
			number = left.variable.number + right/(10^^right.log10.ceil);
		}else{
			if(auto e = cast(ParameterVariable)parser.statements[0].parameters[2])
				parameters[1] = new ParameterLiteral(e.name);
			else
				parameters[1] = parser.statements[0].parameters[2];
		}
		parameters[2] = new ParameterDynamic(Variable());
	}
	
	override Variable get(Stack stack){
		debug(Parameter){
			if(!number.isFinite)
				writeln("INDEX DATA ", container.get(stack), ".", element.get(stack), " = ", stack[indexIndex]([container, element], stack));
		}
		if(number.isFinite)
			return Variable(number);
		else {
			try {
				return stack[indexIndex](parameters[0..2], stack);
			}catch(CommandoError e){
				throw new CommandoError("%s(%s): %s".format(identifier, line, statement), stack, e);
			}
		}
	}

	override void set(Stack stack, Variable v){
		try {
			if(number.isFinite)
				throw new CommandoError("Cannot assign to number");
			parameters[2].to!ParameterDynamic.variable = v;
			stack[indexAssignIndex](parameters[], stack);
		}catch(CommandoError e){
			throw new CommandoError("%s(%s): %s".format(identifier, line, statement), stack, e);
		}
	}

	override void precompute(Stack stack){
		if(!number.isFinite){
			parameters[0].precompute(stack);
			parameters[1].precompute(stack);
		}
	}

}

