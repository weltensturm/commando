
module pike.statements;

import pike;


class Statement {
    string contextIdentifier;
    long line;
    FunctionReturn run(Interpreter, Context){ assert(0); }
}


class Parameter {
    Variable evaluate(Interpreter pike, Context context){ assert(0); }
}

class ParameterLiteral: Parameter {
    string literal;
    bool number;
    
    this(string literal){
        this.literal = literal;
        number = literal.isNumeric;
    }

    override Variable evaluate(Interpreter pike, Context context){
        if(number)
            return new Variable(literal.to!double);
        else
            return new Variable(literal);
    }
}

class ParameterVariable: Parameter {

    string name;

    this(string name){
        this.name = name;
    }

    override Variable evaluate(Interpreter pike, Context context){
        return context.get(name);
    }

}

class ParameterCall: Parameter {

    Statement statement;

    this(string statement, string contextIdentifier, long line){
        this.statement = new Call(statement, contextIdentifier, line);
    }

    override Variable evaluate(Interpreter pike, Context context){
        return statement.run(pike, context)[0];
    }

}


class Call: Statement {

	string command;

	Parameter[] parameters;

	this(string statement, string contextIdentifier, long line){

        this.contextIdentifier = contextIdentifier;
        this.line = line;

        bool inBlock;
        int inBrace;
        char[] current;

        foreach(i, c; statement ~ '\n'){
            if(inBrace){
                if(c == '(')
                    inBrace++;
                if(c == ')')
                    inBrace--;
                current ~= c;
                continue;
            }
            if(c.isWhite || c == ':'){
                if(!command.length && current.length){
                    //writeln("command ", current);
                    command = current.to!string;
                    current = [];
                }else if(current.length){
                    //writeln(current);
                    if(current.startsWith("$"))
                        parameters ~= new ParameterVariable(current[1..$].to!string);
                    else if(current.startsWith("("))
                        parameters ~= new ParameterCall(current[1..$-1].to!string, contextIdentifier, line);
                    else
                        parameters ~= new ParameterLiteral(current.to!string);
                    current = [];
                }
                if(c == ':'){
                    parameters ~= new ParameterLiteral(statement[i+1..$]);
                    //writeln(statement[i+1..$]);
                    break;
                }
                continue;
            }
            if(c == '('){
                inBrace = 1;
            }
            current ~= c;
        }

	}

    override FunctionReturn run(Interpreter pike, Context context){
        try{
            auto var = context.get(command);
            if(!var){
                writeln(context.names);
                throw new PikeError(`Could not resolve name "%s"`.format(command));
            }
            return var(parameters.map!(a => a.evaluate(pike, context)).array, context);
        }catch(PikeError e){
            string[] paramDesc;
            foreach(param; parameters){
                try{
                    paramDesc ~= param.evaluate(pike, context).to!string;
                }catch{
                    paramDesc ~= "(error)";
                }
            }
            throw new PikeError("%s(%s): Called from: %s %s".format(contextIdentifier, line, command, paramDesc.join(" ")), context, e);
        }
    }

	override string toString(){
		return "call %s".format(command);
	}

}


class Assignment: Statement {
	
	string variable;
	
	Statement value;

	this(string statement, string contextIdentifier, long line){

        this.contextIdentifier = contextIdentifier;
        this.line = line;

		foreach(i, c; statement){
			if(c == '='){
				value = new Call(statement[i+1..$], contextIdentifier, line);
				break;
			}
			variable ~= c;
		}
        variable = variable.strip;
		//writeln(this);
	}

    override FunctionReturn run(Interpreter pike, Context context){
        auto res = value.run(pike, context);
        if(!res.length)
            throw new PikeError("%s(%s): Cannot assign to \"%s\": returned nothing".format(contextIdentifier, line, variable), context, null);
        context.set(variable, res[0]);
        return null;
    }

	override string toString(){
		return "%s = %s".format(variable, value);
	}

}
