
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
		stack[stackIndex].assign(var);
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

	Frame frame;

	long line;

	this(bool isFunction, string[] parameters, string block, string identifier, long line){
		this.statement = block;
		this.identifier = identifier;
		this.isFunction = isFunction;
		this.line = line;
		auto parser = new Parser(identifier, line);
		parser.parse(block);
		statements = parser.statements;
		frame = new Frame;
		frame.localNames ~= parameters;
		frame.parameterCount = parameters.length;
	}

	override Variable get(Stack stack){
		Closure closure;
		if(frame.nonlocals.length){
			closure = new Closure;
			foreach(idx; frame.nonlocals)
				closure[idx] = stack[idx];
		}
        return Variable((Parameter[] params, Stack caller){
			debug(Parameter){
				writeln("CALL ", isFunction ? "FN " : "BLOCK ", frame.localNames, " \"", statement, "\"");
			}
			checkLength(frame.parameterCount, params.length);
			stack.push(frame, closure, params);
			foreach(i; frame.captured)
				stack.local[i] = i >= frame.parameterCount ? Variable(Variable.Type.reference) : Variable(&stack.local[i]);
			auto r = run(statements, stack, isFunction);
			stack.pop;
			return r;
        });
	}

	override void collect(Stack stack, void delegate(Variable) unnamed, void delegate(string, Variable) named){
		debug(Parameter){
			writeln("COLLECT ", isFunction ? "FN " : "BLOCK ", frame.localNames, " \"", statement, "\"");
		}
		if(frame.parameterCount)
			throw new CommandoError("Cannot collect parametrized function (for now)");
			
		Closure closure;
		if(frame.nonlocals.length){
			closure = new Closure;
			foreach(idx; frame.nonlocals)
				closure[idx] = stack[idx];
		}
		stack.push(frame, closure);
		foreach(i; frame.captured)
			stack.local[i] = Variable(Variable.Type.reference);
		foreach(statement; statements){
			auto r = statement.run(stack);
			if(r)
				unnamed(r);
			if(checkReturn(false))
				break;
		}
		foreach(i, idx; frame.locals)
			named(frame.localNames[i], stack[idx]);
		stack.pop;
	}

	override void set(Stack context, Variable var){
		throw new Exception("Cannot assign to non-variable");
	}

	override void precompute(Stack stack){
		frame.lexicalLevel = stack.prepush((usedFrom, level, index){
			if(level == 0)
				return;
			if(frame.lexicalLevel == level && usedFrom > level && !frame.captured.canFind(index))
				frame.captured ~= index;
			if(frame.lexicalLevel <= usedFrom && frame.lexicalLevel > level && !frame.nonlocals.canFind(Stack.Pos(level, index))){
				frame.nonlocals ~= Stack.Pos(level, index);
			}
		});
		foreach(a; frame.localNames[0..frame.parameterCount])
			frame.locals ~= stack.register(a);
		foreach(a; statements.map!(s => s.names(stack)).join)
			stack.ensureIndex(a);
		foreach(s; statements)
			s.precompute(stack);
		stack.currentNames((names, indices){
			foreach(i; indices[frame.parameterCount..$]){
				frame.locals ~= i;
			}
		});
		frame.localNames = stack.prepop;
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
				writeln("INDEX DATA ", parameters[0].get(stack), ".", parameters[1].get(stack), " = ", stack[indexIndex](parameters[0..2], stack));
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

