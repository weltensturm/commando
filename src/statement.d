
module commando.statement;

import commando;


class Statement {

	string contextIdentifier;
	long line;
	string lineText;

	Parameter[] parameters;

	this(Parameter[] parameters, string contextIdentifier, long line, string lineText){
		this.contextIdentifier = contextIdentifier;
		this.line = line;
		this.parameters = parameters;
		this.lineText = lineText;
	}

	void precompute(Stack stack){
		try{
			foreach(p; parameters)
				p.precompute(stack);
		}catch(CommandoError e){
			throw new CommandoError("%s(%s): %s".format(contextIdentifier, line, lineText), stack, e);
		}
	}

	string[] names(Stack stack){
		return parameters.map!(a => a.names(stack)).join;
	}

	FunctionReturn run(Stack stack){
		try{
			auto var = parameters[0].get(stack);
			if(var.isCallable)
				return var(parameters[1..$], stack);
			else if(parameters.length > 1)
				throw new CommandoError("Cannot call %s with parameters".format(var.type));
			return [var];
		}catch(CommandoError e){
			throw new CommandoError("%s(%s): %s".format(contextIdentifier, line, lineText), stack, e);
		}
	}

}

