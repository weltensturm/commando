module commando.globals.comparison;

import commando;


void comparison(Stack stack){

	stack["and"] = Variable((Parameter[] params, Stack stack){
        auto p0 = params[0].get(stack);
        if(!p0.boolean)
            return p0;
        return params[1].get(stack);
	});

	stack["then"] = stack["and"];

	stack["or"] = Variable((Parameter[] params, Stack stack){
        auto p0 = params[0].get(stack);
		if(p0.boolean)
            return p0;
        return params[1].get(stack);
	});

	stack["not"] = (bool a) => !a;

	stack["=="] = Variable((Parameter[] params, Stack stack){
		return Variable(params[0].get(stack).equals(params[1].get(stack)));
	});

	stack[">"] = (double a, double b) => a > b;
	
	stack[">="] = (double a, double b) => a >= b;
	
	stack["<"] = (double a, double b) => a < b;
	
	stack["<="] = (double a, double b) => a <= b;

}
