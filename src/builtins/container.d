module commando.builtins.container;

import commando;


void container(Interpreter commando){
    auto container = commando.global;

	container["each"] = (Parameter[] params, Variable context){
		string[] names;
		auto statements = params[$-1].evaluate(context).block;
		if(params.length > 2){
			foreach(i, param; params[0..$-2]){
				if(i == params.length-3 && param.text(context) != "in")
					throw new CommandoError(`"Expected "in", got "%s"`.format(param));
				if(i != params.length-3)
					names ~= param.text(context);
			}
		}
		foreach(key, value; params[$-2].evaluate(context)){
			auto context = .context(context);
			if(names.length > 0)
				context[names[$-1]] = value;
			if(names.length > 1)
				context[names[$-2]] = key;
			foreach(statement; statements){
				statement.run(context);
			}
		}
		return nothing;
	};

	container["range"] = (Parameter[] params, Variable context){
		return [new Variable(
				params[0].evaluate(context).number
				.iota
				.map!(a => new Variable(a))
				.array
		)];
	};

	container["table"] = (Parameter[] params, Variable context){
		if(params.length != 2)
			throw new CommandoError("Expected 2 parameters, got %s".format(params.length));
		auto res = new Variable(Variable.Type.table);

		auto statements = params[$-1].evaluate(context).block;
		int counter;
		auto inner = .context(context);
		foreach(statement; statements){
			auto r = statement.run(inner);
			if(r){
				inner[counter.to!string] = r[0];
				counter++;
			}
			//if("return" in context.variables)
			//	return [context.variables["return"]];
		}
		foreach(name, var; inner){
			res[name.to!string] = var;
		}
		context[params[0].text(context)] = res;
		return nothing;
	};

}
