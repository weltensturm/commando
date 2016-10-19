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
		Statement[] block;
	}

	enum Type {
		null_,
		text,
		number,
		func,
		table,
		block,
		boolean
	}

	Value value;
	Type type;

	this(Type type = Type.null_){
		this.type = type;
		if(type == Type.table)
			value.table = TableValue();
	}

	this(bool boolean){
		value.number = boolean ? 1 : 0;
		type = Type.boolean; 
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

    ref TableValue table(){
        checkType(Type.table);
        return value.table;
    }

    Function func(){
        checkType(Type.func);
        return value.func;
    }

	Statement[] block(){
		checkType(Type.block);
		return value.block;
	}

	bool boolean(){
		checkType(Type.boolean);
		return value.number != 0;
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

	Variable opIndex(string index){
		if(index.isNumeric && index.to!size_t < table.array.length){
			return table.array[index.to!size_t];
		}else{
			if(index !in table.map)
				throw new PikeError(`No member named "%s"`.format(index)); 
			return table.map[index];
		}
	}

	void opIndexAssign(Variable variable, string index){
		if(index.isNumeric && index.to!size_t == table.array.length){
			table.array ~= variable;
		}else{
			table.map[index] = variable;
		}
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
