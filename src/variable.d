module pike.variable;


import pike;


class Variable {

	private struct TableValue {
		Variable[] array;
		Variable[string] map;
	}

	union Value {
		string text;
		double number;
		Function func;
		TableValue table;
	}

	enum Type {
		null_,
		text,
		number,
		func,
		table
	}

	Value value;
	Type type;

	this(){
		type = Type.null_;
	}

    this(Variable[] value){
        this.value.table = TableValue(value);
        type = Type.table;
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

	this(FunctionReturn delegate(Variable[]) value){
		this((Variable[] v, Context c){
			return value(v);
		});
	}

	this(void delegate(Variable[]) value){
		this((Variable[] v, Context c){
			value(v);
			return FunctionReturn.init;
		});
	}

	this(void delegate(Variable[], Context) value){
		this((Variable[] v, Context c){
			value(v, c);
			return FunctionReturn.init;
		});
	}

    void checkType(Type type){
        if(type != this.type)
            throw new PikeError("Type mismatch: expected %s, got %s".format(type, this.type).chomp("_"));
    }

	double number(){
		checkType(Type.number);
		return value.number;
	}

	string text(){
		checkType(Type.text);
		return value.text;
	}

    TableValue table(){
        checkType(Type.table);
        return value.table;
    }

    Function func(){
        checkType(Type.func);
        return value.func;
    }

	Variable[] opCall(Variable[] params, Context context){
		return func()(params, context);
	}

    int opApply(int delegate(Variable, Variable) dg){
        int result = 0;
        foreach(i, v; table.array){
            result = dg(new Variable(i), v);
            if(result)
                return result;
        }
        foreach(k, v; table.map){
            result = dg(new Variable(k), v);
            if(result)
                return result;
        }
        return result;
    }

    void opOpAssign(string op)(Variable variable){
        mixin("table.array " ~ op ~ "= variable;");
    }

	override string toString(){
		if(type == Type.text){
			return value.text;
		}else if(type == Type.number){
			return value.number.to!string;
		}else if(type == Type.func){
			return "function:%s".format(value.func.ptr);
		}else if(type == Type.null_){
            return "null";
        }else if(type == Type.table){
            return "table:%s".format(value.table.array.ptr);
        }else{
			throw new PikeError("Could not convert %s to string".format(type));
		}
	}
}
