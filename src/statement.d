
module pike.statement;

import pike;


class Statement {

    string contextIdentifier;
    long line;

	string command;

	Parameter[] parameters;

	this(string command, Parameter[] parameters, string contextIdentifier, long line){
        this.contextIdentifier = contextIdentifier;
        this.line = line;
        this.command = command;
        this.parameters = parameters;
	}

    FunctionReturn run(Interpreter pike, Context context){
        try{
            auto var = context.get(command);
            if(var.type == Variable.Type.func)
                return var(parameters.map!(a => a.evaluate(pike, context)).array, context);
            else
                return [var];
        }catch(PikeError e){
            string[] paramDesc;
            foreach(param; parameters){
                try{
                    paramDesc ~= param.evaluate(pike, context).to!string;
                }catch{
                    paramDesc ~= "(error)";
                }
            }
            throw new PikeError("%s(%s): %s %s".format(contextIdentifier, line, command, paramDesc.join(" ")), context, e);
        }
    }

	override string toString(){
		return "call %s".format(command);
	}

}
