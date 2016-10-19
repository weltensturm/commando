
module pike.builtins;

import pike;


void loadBuiltins(Interpreter pike){

    auto builtins = pike.contexts["builtins"];

    builtins["fn"] = (Variable[] params, Context context){
        auto names = params[0..$-1];
        auto block = params[$-1].block;
        return [
            new Variable((Variable[] values){
                if(names.length != values.length)
                    throw new PikeError("Expected %s parameter(s), got %s".format(params.length-1, values.length));
                auto context = new Context("fn", context);
                foreach(i, name; names)
                    context[name.text] = values[i];
                foreach(statement; block){
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
        string[] names;
        auto statements = params[$-1].block;
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

    builtins["table"] = (Variable[] params, Context context){
        if(params.length != 2)
            throw new PikeError("Expected 2 parameters, got %s".format(params.length));
        auto res = new Variable(Variable.Type.table);

        auto statements = params[$-1].block;
        int counter;
        auto inner = new Context("fn", context);
        foreach(statement; statements){
            auto r = statement.run(pike, inner);
            if(r){
                inner.set(counter.to!string, r[0]);
                counter++;
            }
            //if("return" in context.variables)
            //    return [context.variables["return"]];
        }
        foreach(name, var; inner.variables)
            res[name] = var;
        context[params[0].text] = res;
    };

    builtins["+"] = (Variable[] params, Context context){
        if(params.length != 2)
            throw new PikeError("Expected 2 parameters, got %s".format(params.length));
        return [new Variable(params[0].number + params[1].number)];
    };

    builtins["="] = (Variable[] params, Context context){
        if(params.length != 2)
            throw new PikeError("Expected 2 parameters, got %s".format(params.length));
        context[params[0].text] = params[1];
    };

    builtins["import"] = (Variable[] params, Context context){
        pike.load(params[0].text);
        context.imported ~= pike.contexts[params[0].text];
    };

    builtins["error"] = (Variable[] params, Context context){
        throw new PikeError(params.map!(a => a.text).join(" "));
    };

    builtins["if"] = (Variable[] params, Context context){
        if(params[0].boolean){
            auto inner = new Context("if", context);
            foreach(statement; params[1].block){
                statement.run(pike, inner);
                if("return" in inner.variables){
                    context["return"] = inner.variables["return"];
                    return;
                }
            }
            context["else"] = (Variable[] params, Context context){
                context.variables.remove("else");
            };
        }else{
            context["else"] = (Variable[] params, Context context){
                auto inner = new Context("else", context);
                foreach(statement; params[0].block){
                    statement.run(pike, inner);
                    if("return" in inner.variables){
                        context["return"] = inner.variables["return"];
                        return;
                    }
                }
                context.variables.remove("else");
            };
        }
    };

    builtins["true"] = new Variable(true);

    builtins["false"] = new Variable(false);

}

void loadFn(Interpreter pike){
}

void loadEcho(Interpreter pike){
    pike.contexts["builtins"].set("echo", new Variable((Variable[] params){
        params.map!(a => a.to!string).join(' ').writeln;
    }));
}
