module commando.globals.container;

import commando;


void container(Stack stack){

    stack["each"] = Variable((Parameter[] params, Stack stack){
    	auto func = params[$-1].get(stack).func;
		auto count = params[$-1].to!ParameterFunction.argTargets.length;
		Parameter[] keyvalue;
		keyvalue.length = count;
        auto res = Variable(Variable.Type.data);
    	foreach(key, value; params[0].get(stack)){
			if(keyvalue.length > 0)
				keyvalue[$-1] = new ParameterDynamic(value);
			if(keyvalue.length > 1)
				keyvalue[0] = new ParameterDynamic(key);
			res ~= func(keyvalue, stack)[0];
    	}
    	return [res];
    });

	stack["range"] = Variable((Parameter[] params, Stack stack){
		return [Variable(
				params[0].get(stack).number
				.iota
				.map!(a => Variable(a))
				.array
		)];
	});

    stack["length"] = Variable((Parameter[] params, Stack stack){
        return params.map!(a => Variable(a.get(stack).data.array.length)).array;
    });

	stack["data"] = Variable((Parameter[] params, Stack stack){
		auto res = Variable(Variable.Type.data);
		if(params.length > 0){
			checkLength(1, params.length);
			int counter;
			params[0].collect(
				stack,
				(v){ res ~= v; },
				(name, v){ res[name] = v; }
			);
		}
		return [res];
	});

	stack["append"] = Variable((Parameter[] params, Stack stack){
		checkLength(2, params.length);
		params[0].get(stack) ~= params[1].get(stack);
		return nothing;
	});

    stack["~="] = stack["append"];

}
