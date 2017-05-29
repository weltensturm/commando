module commando.globals.language;

import commando;


Stack.Pos returnIndex;


Variable noop;


Stack.Pos indexIndex;
Stack.Pos indexAssignIndex;
Stack.Pos assignIndex;


void language(Stack stack){

    noop = Variable((Parameter[] params, Stack stack){
        return nothing;
    });

    returnIndex = stack.register("__return");
    stack[returnIndex] = Variable(Variable.Type.data);

    stack["return"] = Variable(delegate Variable[](Parameter[] params, Stack stack){
		if(!params.length)
			stack[returnIndex] = Variable(nothing);
		else
	        stack[returnIndex] = Variable(params.map!(a => a.get(stack)).array);
        return nothing;
    });

    stack["addr"] = Variable((Parameter[] params, Stack stack){
        return params.map!(a => (Variable((cast(void*)&a.get(stack).value).to!string))).array;
    });

    indexIndex = stack.register(".");
    indexAssignIndex = stack.register(".=");

    stack[indexIndex] = Variable((Parameter[] params, Stack stack){
        checkLength(2, params.length);
        return [params[0].get(stack)[params[1].get(stack)]];
    });

    stack[indexAssignIndex] = Variable((Parameter[] params, Stack stack){
        checkLength(3, params.length);
        auto left = params[0].get(stack);
        left[params[1].get(stack)] = params[2].get(stack);
        return nothing;
    });

    assignIndex = stack.register("=");

    stack[assignIndex] = Variable((Parameter[] params, Stack stack){
    	checkLength(2, params.length);
        params[0].set(stack, params[1].get(stack));
        return nothing;
    });

    stack["import"] = Variable(function Variable[](Parameter[] params, Stack stack){
        /+
        auto imported = commando.load(params[0].text(stack));
        stack["__imported"] ~= imported;
        +/
        assert(0);
    });

    stack["error"] = Variable(function Variable[](Parameter[] params, Stack stack){
        throw new CommandoError(params.map!(a => a.get(stack).text).join(" "));
    });

    stack["check"] = Variable((Parameter[] params, Stack stack){
    	checkLength(1, params.length);
        foreach(p; params){
                if(!p.get(stack).to!bool)
                    throw new CommandoError("Check failed: (" ~ p.statement ~ ")");
        }
        return params.map!(a => a.get(stack)).array;
    });

    auto elseIndex = stack.register("else");

    stack[elseIndex] = noop;

    stack["if"] = Variable((Parameter[] params, Stack stack){
        if(params[0].get(stack).boolean){
            auto result = params[1].get(stack)([], stack);
            if(stack[returnIndex].type != Variable.Type.null_)
                return nothing;
            stack[elseIndex] = noop;
            return result;
        }else{
            stack[elseIndex] = Variable((Parameter[] params, Stack stack){
                checkLength(1, params.length);
                auto result = params[0].get(stack)([], stack);
                if(stack[returnIndex].type != Variable.Type.null_)
                    return nothing;
                stack[elseIndex] = noop;
                return result;
            });
        }
        return nothing;
    });

    stack["|"] = Variable((Parameter[] params, Stack stack){
    	checkLength(2, params.length);
        foreach(s; params[1].to!ParameterCall.statements){
        	if(s.parameters.length >= 2 && s.parameters[1] != params[0])
	            s.parameters = s.parameters[0..1]
	                           ~ new ParameterDynamic(params[0].get(stack))
	                           ~ s.parameters[1..$];
        }
        return [params[1].get(stack)];
    });

}
