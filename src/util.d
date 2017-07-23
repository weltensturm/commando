module commando.util;

import commando;


alias FunctionReturn = Variable[];
alias Function = FunctionReturn delegate(Parameter[], Stack);


auto nothing(){
    return [Variable()];
}


void checkLength(long expected, long actual){
    if(expected != actual)
        throw new CommandoError("Expected %s parameter(s), got %s".format(expected, actual));
}


FunctionReturn checkReturn()(auto ref Stack stack, bool remove=false){
    if(!stack[returnIndex].data.array.length)
        return [];
	Variable[] result;
	foreach(i, a; stack[returnIndex])
		result ~= a;
	if(remove)
		stack[returnIndex] = Variable(Variable.Type.data);
	return result;
}


Variable[] run()(auto ref Statement[] statements, auto ref Stack stack, bool remove){
	Variable[] result;
    foreach(statement; statements){
        auto res = statement.run(stack);
        if(auto a = stack.checkReturn(remove))
            return a;
        result = res;
    }
    return result;
}


auto iter(alias dg, T)(T start){
    struct Iter {
        T current;
        bool empty(){ return current is null; }
        void popFront(){ current = dg(current).to!T; }
        T front(){ return current; }
    }
    return Iter(start);
}


void printData(Variable variable, size_t level=1, Variable[] datas=(Variable[]).init){
    if(level == 1)
        writeln("[");
    foreach(k, v; variable){
        if(v.type == Variable.Type.data){
            if(v == variable)
                writeln("|   ".repeat(level).join, k, " = this");
            else {
                writeln("|   ".repeat(level).join, k, ": ", variable);
                if(!datas.canFind(v))
                    printData(v, level+1, datas ~= v);
            }
        }else
            writeln("|   ".repeat(level).join, k, " = ", v);
    }
    if(level == 1)
        writeln("]");
}


void printStack(Stack stack){
/*    writeln("Stack:");
    foreach(idx, n; stack.names)
        writeln("%s   %s = %s".format(idx, n, stack.stack[idx]));*/
}

