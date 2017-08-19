module commando.variable;


import commando;


Variable construct()(FunctionReturn delegate(Parameter[], Stack) fn){
    return Variable(fn);
}

Variable construct()(FunctionReturn function(Parameter[], Stack) fn){
    return Variable(fn.toDelegate);
}

Variable construct(Ret, Args...)(Ret delegate(Args) fn){
    return Variable((Parameter[] params, Stack context){
        Args args;
        foreach(i, ref a; args){
            a = cast(Args[i])params[i].get(context);
        }
        static if(is(Ret == void)){
            fn(args);
            return nothing;
        }else{
            return Variable(fn(args));
        }
    });
}

Variable construct(Ret, Args...)(Ret function(Args) fn){
    return construct(fn.toDelegate);
}

Variable construct(T)(auto ref T value) if(!isFunctionPointer!T && !isDelegate!T) {
    return Variable(value);
}


struct Variable {

    private class Data {
        Variable[] array;
        Variable[string] map;
    }

    union Value {
        string text;
        double number;
        Function dele;
        FunctionReturn function(Parameter[], Stack) func;
        Data data;
        Object variant;
        Variable* reference;
    }

    enum Type {
        null_ = 1,
        text = 2,
        number = 4,
        func = 8,
        dele = 16,
        data = 32,
        boolean = 64,
        variant = 128,
        reference = 256
    }

    Value value;
    Type type;

    this(Type type){
        this.type = type;
        if(type == Type.data)
            value.data = new Data;
        else if(type == Type.reference)
            value.reference = new Variable(Type.null_);
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
        this.value.dele = value;
        type = Type.dele;
    }

    this(FunctionReturn function(Parameter[], Stack) value){
        this.value.func = value;
        type = Type.func;
    }

    this(Object value){
        this.value.variant = value;
        type=type.variant;
    }

    this(Variable* pointer){
        value.reference = new Variable;
        value.reference.value = pointer.value;
        value.reference.type = pointer.type;
        type = Type.reference;
    }

    void checkType(Type type){
        if(this.type == Type.reference)
            return value.reference.checkType(type);
        else if(!(type & this.type))
            throw new CommandoError("Type mismatch: expected %s, got %s".format(type, this.type).chomp("_"));
    }

    ref Type getType(){
        if(type == Type.reference)
            return value.reference.getType;
        return type;
    }

    ref Value getValue(){
        if(type == Type.reference)
            return value.reference.getValue;
        return value;
    }

    ref double number(){
        checkType(Type.number);
        return getValue.number;
    }

    ref string text(){
        checkType(Type.text);
        return getValue.text;
    }

    Data data(){
        checkType(Type.data);
        return getValue.data;
    }

    bool boolean(){
        if(isNull)
            return false;
        if(getType == Type.boolean)
            return getValue.number != 0;
        return true;
    }

    bool isNull(){
        return getType == Type.null_;
    }

    bool isCallable(){
        return cast(bool)(getType & (Type.func | Type.dele));
    }

    bool equals(Variable other){
        if(getType != other.getType)
            return false;
        final switch(type){
            case Type.boolean:
                return boolean == other.boolean;
            case Type.text:
                return text == other.text;
            case Type.null_:
                return true;
            case Type.func:
                return value.func == other.value.func;
            case Type.dele:
                return value.dele == other.value.dele;
            case Type.data:
                return data == other.data;
            case Type.number:
                return number == other.number;
            case Type.variant:
                return value.variant == other.value.variant;
            case Type.reference:
                return value.reference.equals(other);
        }
    }

    void assign(Variable var){
        if(type == Type.reference)
            (*value.reference).assign(var);
        else {
            value = var.getValue;
            type = var.getType;
        }
    }

    T opCast(T)(){
        static if(is(T == bool))
            return boolean;
        else static if(std.traits.isNumeric!T)
            return number.to!T;
        else static if(is(T == string))
            return text;
        else {
            checkType(Type.variant);
            if(auto v = cast(T)value.variant)
                return v;
            else
                throw new CommandoError("Type mismatch: expected %s, got %s".format(typeid(T).to!string, typeid(value.variant).to!string));
        }
    }

    FunctionReturn opCall()(auto ref Parameter[] params, auto ref Stack context){
        checkType(Type.func | Type.dele);
        if(getType == Type.func)
            return getValue.func(params, context);
        else
            return getValue.dele(params, context);
    }

    int opApply(int delegate(Variable, Variable) dg){
        int result = 0;
        if(getType == Type.text){
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

    Variable find(string index){
        debug(Data){
            writeln("searching ", this, " for ", index);
        }
        if(index in data.map)
            return this;
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
        if(v.getType == Type.number)
            return opIndex(v.number);
        else
            return opIndex(v.text);
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
        this[index] = construct(fn);
    }

    void opIndexAssign(Ret, Args...)(Ret function(Args) fn, string index){
        opIndexAssign(fn.toDelegate, index);
    }

    void opIndexAssign(T)(T variable, string index)
            if(!isFunctionPointer!T && !isDelegate!T
                || is(T == FunctionReturn function(Parameter[], Variable))
                || is(T == FunctionReturn delegate(Parameter[], Variable))) {
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
            return "function:%s".format(&value.func);
        }else if(type == Type.dele){
            return "delegate:%s".format(value.dele.ptr);
        }else if(type == Type.null_){
            return "null";
        }else if(type == Type.data){
            return "data:%s&%s".format(value.data.array.ptr, cast(void*)value.data.map);
        }else if(type == Type.boolean){
            return boolean.to!string;
        }else if(type == Type.reference){
            return value.reference.toString;
        }else{
            throw new CommandoError("Could not convert %s to string".format(type));
        }
    }
}
