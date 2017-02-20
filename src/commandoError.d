module commando.commandoError;


import commando;


class CommandoError: Exception {

	CommandoError parent;
	Variable context;

	this(string error){
		super(error);
	}

	this(string error, Variable context, CommandoError parent, string file = __FILE__, size_t line = __LINE__){
		this.parent = parent;
		this.context = context;
		super(error, file, line);
	}

	override string toString(){
		if(parent)
			return parent.toString ~ "\n  " ~ msg;
		return "  " ~ msg;
	}

	string trace(){
		return super.toString;
	}

	Variable parentContext(){
		auto p = this;
		while(p.parent && p.parent.context)
			p = p.parent;
		return p.context;
	}

}
