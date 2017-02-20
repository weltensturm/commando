module commando.builtins.comparison;

import commando;


void comparison(Interpreter commando){
    auto comparison = commando.global;

	comparison["and"] = (Parameter[] params, Variable context){
		return [new Variable(
            params[0].evaluate(context).boolean
            && params[1].evaluate(context).boolean
        )];
	};

	comparison["or"] = (Parameter[] params, Variable context){
		return [new Variable(
            params[0].evaluate(context).boolean
            || params[1].evaluate(context).boolean
        )];
	};

	comparison[">"] = (Parameter[] params, Variable context){
		return [new Variable(
            params[0].evaluate(context).number
            > params[1].evaluate(context).number
        )];
	};

	comparison[">="] = (Parameter[] params, Variable context){
		return [new Variable(
            params[0].evaluate(context).number
            >= params[1].evaluate(context).number
        )];
	};

	comparison["<"] = (Parameter[] params, Variable context){
		return [new Variable(
            params[0].evaluate(context).number
            < params[1].evaluate(context).number
        )];
	};

	comparison["<="] = (Parameter[] params, Variable context){
		return [new Variable(
            params[0].evaluate(context).number
            <= params[1].evaluate(context).number
        )];
	};

}
