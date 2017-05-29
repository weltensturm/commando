module commando.variable;


import commando;


struct Variable {

	private class Data {
		Variable[] array;
		Variable[string] map;
	}

	union Value {
		string text;
		double number;
		Function func;
		Data data;
	}

	enum Type {
		null_ = 1,
		text = 2,
		number = 4,
		func = 8,
		data = 16,
		boolean = 32
	}

	Value value;
	Type type;

	this(Type type){
		this.type = type;
		if(type == Type.data)
			value.data = new Data;
	}

	this(bool boolean){
		value.number = boolean ? 1 : 0;
		type = Type.boolean;
	}

	this(Variable[] value){
		this.value.data = new Data;
		this.value.data.array = value;
		type = Type.data;
	}

	this(string value){
		this.value.text = value;
		type = Type.text;
	}

	this(double value){
		this.value.number = value;
		type = Type.number;
	}

	this(Function value){
		this.value.func = value;
		type = Type.func;
	}

	this(FunctionReturn function(Parameter[], Stack) value){
		this(value.toDelegate);
	}

	void checkType(Type type){
		if(!(type & this.type))
			throw new CommandoError("Type mismatch: expected %s, got %s".format(type, this.type).chomp("_"));
	}

	ref double number(){
		checkType(Type.number);
		return value.number;
	}

	ref string text(){
		checkType(Type.text);
		return value.text;
	}

	Data data(){
		checkType(Type.data);
		return value.data;
	}

	ref Function func(){
		checkType(Type.func);
		return value.func;
	}

	bool boolean(){
		if(isNull)
			return false;
		if(type == Type.boolean)
			return value.number != 0;
		return true;
	}

	bool isNull(){
		return type == Type.null_;
	}

	bool equals(Variable other){
		if(type != other.type)
			return false;
		final switch(type){
			case Type.boolean:
				return boolean == other.boolean;
			case Type.text:
				return text == other.text;
			case Type.null_:
				return true;
			case Type.func:
				return func == other.func;
			case Type.data:
				return data == other.data;
			case Type.number:
				return number == other.number;
		}
	}

	T opCast(T)(){
		static if(is(T == bool))
			return boolean;
		else static if(isNumeric!T)
			return number.to!T;
		else static if(is(T == string))
			return text;
	}

	Variable[] opCall(Parameter[] params, Stack context){
		return func()(params, context);
	}

	int opApply(int delegate(Variable, Variable) dg){
		int result = 0;
		if(type == Type.text){
			foreach(i, v; text){
				result = dg(Variable(i), Variable(v.to!string));
				if(result)
					return result;
			}
		}else{
			foreach(i, v; data.array){
				result = dg(Variable(i), v);
				if(result)
					return result;
			}
			foreach(k, v; data.map){
				result = dg(Variable(k), v);
				if(result)
					return result;
			}
		}
		return result;
	}

	Variable find(string index, bool imports=true){
		debug(Data){
			writeln("searching ", this, " for ", index);
		}
		if(index in data.map)
			return this;
		if(imports && "__imported" in data.map){
			foreach(_, imp; data.map["__imported"]){
				if(index in imp.data.map)
					return imp;
			}
		}
		if("__index" in data.map)
			return data.map["__index"].find(index);
		return Variable();
	}

	Variable opIndex(string index){
		if(index.isNumeric && index.to!size_t < data.array.length){
			return data.array[index.to!size_t];
		}
		auto var = find(index);
		if(var.isNull || index !in var.data.map)
			throw new CommandoError(`No member "%s"`.format(index));
		return var.data.map[index];

	}

	Variable opIndex(double index){
		if(index < data.array.length){
			return data.array[index.to!size_t];
		}
		return opIndex(index.to!string);
	}

	Variable opIndex(Variable v){
		if(v.type == Type.number)
			return opIndex(v.number);
		else
			return opIndex(v.text);
	}

	Variable slot(string index){
		if(index.isNumeric && index.to!size_t == data.array.length)
			data.array ~= Variable();
		if(index.isNumeric && index.to!size_t < data.array.length){
			return data.array[index.to!size_t];
		}
		auto var = find(index, false);
		if(var.isNull || index !in var.data.map){
			var = Variable();
			data.map[index] = var;
		}
		return var;

	}

	void opIndexAssign()(Variable variable, string index){
		if(index.isNumeric && index.to!size_t == data.array.length){
			data.array ~= variable;
		}else{
			data.map[index] = variable;
		}
	}

	void opIndexAssign()(Variable delegate(Parameter[], Stack) fn, string index){
		data.map[index] = Variable(fn);
	}

	void opIndexAssign(Ret, Args...)(Ret delegate(Args) fn, string index){
		this[index] = (Parameter[] params, Stack context){
			Args args;
			foreach(i, ref a; args){
				a = cast(Args[i])params[i].get(context);
			}
			static if(is(Ret == void)){
				fn(args);
				return nothing;
			}else
				return cast(Ret)fn(args);
		};
	}

	void opIndexAssign(Ret, Args...)(Ret function(Args) fn, string index){
		opIndexAssign(fn.toDelegate, index);
	}

	void opIndexAssign(T)(T variable, string index)
			if(!isFunctionPointer!T && !isDelegate!T
				|| is(T == Variable[] function(Parameter[], Variable))
				|| is(T == Variable[] delegate(Parameter[], Variable))) {
		opIndexAssign(Variable(variable), index);
	}

	void opOpAssign(string op)(Variable variable){
		mixin("data.array " ~ op ~ "= variable;");
	}

	void opIndexAssign(Variable v, Variable n){
		opIndexAssign(v, n.text);
	}

	/+
	Proxy opDispatch(string name)(){
		return new Proxy(this, name);
	}
	+/

	string toString(){
		if(type == Type.text){
			return value.text;
		}else if(type == Type.number){
			return value.number.to!string;
		}else if(type == Type.func){
			return "function:%s".format(value.func.ptr);
		}else if(type == Type.null_){
			return "null";
		}else if(type == Type.data){
			return "data:%s&%s".format(value.data.array.ptr, cast(void*)value.data.map);
		}else if(type == Type.boolean){
			return boolean.to!string;
		}else{
			throw new CommandoError("Could not convert %s to string".format(type));
		}
	}
}
