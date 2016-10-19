module pike.context;


import pike;


class Context {

	string name;

	Context[] imported;

	Context parent;

	Variable[string] variables;

	this(string name, Context parent){
		this.name = name;
		this.parent = parent;
	}

	void set(string name, Variable variable, bool force=false){
		auto p = this;
		while(!force && p && name !in p.variables)
			p = p.parent;
		if(force || !p)
			p = this;
		p.variables[name] = variable;
	}

	Variable get(string name, bool throw_=true){
		string[] index;
		Variable var;
		if(name.canFind(".")){
			index = name.split(".")[1..$];
			name = name.split(".")[0];
		}
		if(name in variables)
			var = variables[name];
		else {
			foreach(i; imported){
				auto ivar = i.get(name, false);
				if(ivar && var)
					throw new PikeError(`Ambiguous name "%s"`.format(name));
				else if(ivar)
					var = ivar;
			}
			if(parent && !var)
				return parent.get(name, throw_);
		}
		if(!var && throw_)
			throw new PikeError(`Could not resolve "%s"`.format(name));
		foreach(sub; index){
			var = var[sub];
		}
		return var;
	}

	void opIndexAssign(Variable var, string index){
		set(index, var);
	}

	void opIndexAssign(T)(T value, string index) if(!is(T == Variable)) {
        static if(isCallable!T){
		    set(index, new Variable(value.toDelegate));
        }else{
		    set(index, new Variable(value));
        }
	}

	Variable opIndex(string index){
		return get(index);
	}

	string names(){
		auto s = "  %s:\n".format(name);
        foreach(name, var; variables)
            s ~= "    %s = %s\n".format(name, var);
		foreach(i; imported)
			s ~= i.names;
		if(parent)
			s ~= parent.names;
		return s;
	}

}
