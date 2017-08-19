module commando.globals.container;

import commando;


Stack.Pos appendIndex;


void container(Stack stack){

	ParameterDynamic[2] iterParams = [new ParameterDynamic, new ParameterDynamic];

    stack["each"] = Variable((Parameter[] params, Stack stack){
    	auto func = params[$-1].get(stack);
		auto count = params[$-1].to!ParameterFunction.frame.parameterCount;
        auto res = nothing;
    	foreach(key, value; params[0].get(stack)){
			if(count > 0)
				iterParams[$-1].variable = value;
			if(count > 1)
				iterParams[0].variable = key;
			res = func(iterParams[2-count..$].to!(Parameter[]), stack);
    	}
    	return res;
    });

    stack["map"] = Variable((Parameter[] params, Stack stack){
        auto func = params[$-1].get(stack);
        auto count = params[$-1].to!ParameterFunction.frame.parameterCount;
		auto data = params[0].get(stack);
        auto res = Variable(Variable.Type.data);
		res.data.array.length = data.data.array.length + data.data.map.length;
		size_t counter;
    	foreach(key, value; data){
			if(count > 0)
				iterParams[$-1].variable = value;
			if(count > 1)
				iterParams[0].variable = key;
            res.data.array[counter++] = func(iterParams[2-count..$].to!(Parameter[]), stack);
        }
        return res;
    });

	stack["range"] = Variable((Parameter[] params, Stack stack){
		return Variable(
				params[0].get(stack).number
				.iota
				.map!(a => Variable(a))
				.array
		);
	});

    stack["length"] = Variable((Parameter[] params, Stack stack){
        return Variable(params[0].get(stack).data.array.length);
    });

	stack["data"] = Variable((Parameter[] params, Stack stack){
		auto res = Variable(Variable.Type.data);
		if(params.length > 0){
			checkLength(1, params.length);
			params[0].collect(
				stack,
				(v){ res ~= v; },
				(name, v){ res[name] = v; }
			);
		}
		return res;
	});

	stack["append"] = Variable((Parameter[] params, Stack stack){
		checkLength(2, params.length);
		params[0].get(stack) ~= params[1].get(stack);
		return nothing;
	});

    stack["~="] = stack["append"];

}
