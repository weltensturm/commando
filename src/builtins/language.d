module commando.builtins.language;

import commando;


void language(Interpreter commando){
    auto language = commando.global;

	language["fn"] = (Parameter[] params, Variable context){
		auto names = params[0..$-1].map!(a => a.text(context));
		auto block = params[$-1].evaluate(context).block;
		return [
			new Variable((Parameter[] values, Variable _){
				if(names.length != values.length)
					throw new CommandoError("Expected %s parameter(s), got %s".format(params.length-1, values.length));
				Variable[] return_;
				auto context = .context(context);
				context["return"] = (Parameter[] params, Variable context){
					return_ = params.map!(a => a.evaluate(context)).array;
					return nothing;
				};

				foreach(i, name; names.enumerate)
					context[name.text] = values[i].evaluate(context);
				foreach(statement; block){
					auto res = statement.run(context);
					if(return_)
						return return_;
				}
				return nothing;
			})
		];
	};

	language["."] = (Parameter[] params, Variable context){
		auto left = params[0].evaluate(context);
		if(left.type == Variable.Type.number){
			auto right = params[1].evaluate(context);
			return [new Variable(left.number + right.number/(10^^right.number.log10.ceil))];
		}else{
			return [left[params[1].text(context)]];
		}
	};

	language["="] = (Parameter[] params, Variable context){
		if(params.length != 2)
			throw new CommandoError("Expected 2 parameters, got %s".format(params.length));
		context[params[0].text(context)] = params[1].evaluate(context);
		return nothing;
	};

	language["import"] = (Parameter[] params, Variable context){
		auto imported = commando.load(params[0].text(context));
		context["__imported"] ~= imported;
		return nothing;
	};

	language["error"] = function Variable[](Parameter[] params, Variable context){
		throw new CommandoError(params.map!(a => a.evaluate(context).text).join(" "));
	};

	language["if"] = (Parameter[] params, Variable context){
		if(params[0].evaluate(context).boolean){
			auto inner = .context(context);
			foreach(statement; params[1].evaluate(context).block){
				statement.run(inner);
				if("__return" in inner.table.map){
					context["__return"] = inner["__return"];
					return nothing;
				}
			}
			context["else"] = (Parameter[] params, Variable context){
				context.table.map.remove("else");
				return nothing;
			};
		}else{
			context["else"] = (Parameter[] params, Variable context){
				auto inner = .context(context);
				foreach(statement; params[0].evaluate(context).block){
					statement.run(inner);
					if("return" in inner.table.map){
						context["__return"] = inner.table.map["__return"];
						return nothing;
					}
				}
				context.table.map.remove("else");
				return nothing;
			};
		}
		return nothing;
	};


}
