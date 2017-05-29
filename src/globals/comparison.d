module commando.globals.comparison;

import commando;


void comparison(Stack stack){

	stack["and"] = Variable((Parameter[] params, Stack stack){
        auto p0 = params[0].get(stack);
        if(!p0.boolean)
            return [p0];
        return [params[1].get(stack)];
	});

	stack["or"] = Variable((Parameter[] params, Stack stack){
        auto p0 = params[0].get(stack);
		if(p0.boolean)
            return [p0];
        return [params[1].get(stack)];
	});

	stack["not"] = Variable((Parameter[] params, Stack stack){
		return [Variable(!params[0].get(stack).boolean)];
	});

	stack["=="] = Variable((Parameter[] params, Stack stack){
		return [Variable(params[0].get(stack).equals(params[1].get(stack)))];
	});

	stack[">"] = Variable((Parameter[] params, Stack stack){
		return [Variable(
            params[0].get(stack).number
            > params[1].get(stack).number
        )];
	});

	stack[">="] = Variable((Parameter[] params, Stack stack){
		return [Variable(
            params[0].get(stack).number
            >= params[1].get(stack).number
        )];
	});

	stack["<"] = Variable((Parameter[] params, Stack stack){
		return [Variable(
            params[0].get(stack).number
            < params[1].get(stack).number
        )];
	});

	stack["<="] = Variable((Parameter[] params, Stack stack){
		return [Variable(
            params[0].get(stack).number
            <= params[1].get(stack).number
        )];
	});

}
