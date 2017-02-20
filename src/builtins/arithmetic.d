module commando.builtins.arithmetic;

import commando;


void arithmetic(Interpreter commando){
    auto arithmetic = commando.global;

	arithmetic["+"] = (Parameter[] params, Variable context){
		if(params.length != 2)
			throw new CommandoError("Expected 2 parameters, got %s".format(params.length));
		return [new Variable(params[0].evaluate(context).number + params[1].evaluate(context).number)];
	};

	arithmetic["-"] = (Parameter[] params, Variable context){
		if(params.length != 2)
			throw new CommandoError("Expected 2 parameters, got %s".format(params.length));
		return [new Variable(params[0].evaluate(context).number - params[1].evaluate(context).number)];
	};

	arithmetic["*"] = (Parameter[] params, Variable context){
		if(params.length != 2)
			throw new CommandoError("Expected 2 parameters, got %s".format(params.length));
		return [new Variable(params[0].evaluate(context).number * params[1].evaluate(context).number)];
	};

	arithmetic["/"] = (Parameter[] params, Variable context){
		if(params.length != 2)
			throw new CommandoError("Expected 2 parameters, got %s".format(params.length));
		return [new Variable(params[0].evaluate(context).number / params[1].evaluate(context).number)];
	};

}
