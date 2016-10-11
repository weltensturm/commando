
module pike.builtins;

import pike;


void loadBuiltins(Interpreter pike){

    auto builtins = pike.contexts["builtins"];

    builtins["fn"] = (Variable[] params, Context context){
        auto names = params[0..$-1];
        auto block = params[$-1].text;
        auto statements = pike.parse("fn", block);
        return [
            new Variable((Variable[] values){
                if(names.length != values.length)
                    throw new PikeError("Expected %s parameter(s), got %s".format(params.length-1, values.length));
                auto context = new Context("fn", context);
                foreach(i, name; names)
                    context[name.text] = values[i];
                foreach(statement; statements){
                    auto res = statement.run(pike, context);
                    if("return" in context.variables)
                        return [context.variables["return"]];
                }
                return FunctionReturn.init;
            })
        ];
    };

    builtins["return"] = (Variable[] params, Context context){
        if(!params.length)
            context.variables["return"] = new Variable;
        context.variables["return"] = params[0];
    };

    builtins["each"] = (Variable[] params, Context context){
        writeln(params);
        string[] names;
        auto statements = pike.parse("each", params[$-1].text);
        if(params.length > 2){
            foreach(i, param; params){
                if(i == params.length-3 && param.text != "in")
                    throw new PikeError(`"Expected "in", got "%s"`.format(param));
                else if(i < params.length-3){
                    names ~= param.text;
                }
            }
        }
        foreach(key, value; params[$-2]){
            auto context = new Context("each", context);
            if(names.length > 0)
                context[names[$-1]] = value;
            if(names.length > 1)
                context[names[$-2]] = key;
            foreach(statement; statements){
                statement.run(pike, context);
            }
        }
        return FunctionReturn.init;
    };

    builtins["range"] = (Variable[] params, Context context){
        return [new Variable(
                params[0].number
                .iota
                .map!(a => new Variable(a))
                .array
        )];
    };

    builtins["+"] = (Variable[] params, Context context){
        if(params.length != 2)
            throw new Exception("Expected 2 parameters, got %s".format(params.length));
        return [new Variable(params[0].number + params[1].number)];
    };

}

void loadFn(Interpreter pike){
}

void loadEcho(Interpreter pike){
    pike.contexts["builtins"].set("echo", new Variable((Variable[] params){
        params.map!(a => a.to!string).join(' ').writeln;
    }));
}
