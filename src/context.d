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

	void set(string name, Variable variable){
		auto p = this;
		while(p && name !in p.variables)
			p = p.parent;
		if(!p)
			p = this;
		p.variables[name] = variable;
	}

	Variable get(string name){
		if(name in variables)
			return variables[name];
		if(parent)
			return parent.get(name);
		int count = 1;
		Variable var;
		foreach(i; imported){
			auto ivar = i.get(name);
			if(ivar && var)
				throw new PikeError(`Ambiguous name "%s"`.format(name));
			else if(ivar)
				var = ivar;
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
		auto s = "%s:\n".format(name);
        foreach(name, var; variables)
            s ~= "\t%s = %s\n".format(name, var);
		foreach(i; imported)
			s ~= i.names;
		if(parent)
			s ~= parent.names;
		return s;
	}

}
