
module commando.statement;

import commando;


class Statement {

	string contextIdentifier;
	long line;

	Parameter[] parameters;

	this(Parameter[] parameters, string contextIdentifier, long line){
		this.contextIdentifier = contextIdentifier;
		this.line = line;
		this.parameters = parameters;
	}

	FunctionReturn run(Variable context){
		try{
			auto var = parameters[0].evaluate(context);
			if(!var || var.type == Variable.Type.null_)
				throw new CommandoError("Cannot call null");
			else if(var.type == Variable.Type.func)
				return var(parameters[1..$], context);
			else
				return [var];
		}catch(CommandoError e){
			//writeln("STATEMENT ", command);
			//context.printTable;
			string[] paramDesc;
			foreach(param; parameters[1..$]){
				try{
					paramDesc ~= param.statement;
				}catch(Throwable){
					paramDesc ~= param.to!string;
				}
			}
			throw new CommandoError("%s(%s): %s".format(contextIdentifier, line, paramDesc.join(" ")), context, e);
		}
	}

}
