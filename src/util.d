module commando.util;

import commando;


alias FunctionReturn = Variable;
alias Function = FunctionReturn delegate(Parameter[], Stack);


auto nothing(){
    return Variable();
}


void checkLength(long expected, long actual){
    if(expected != actual)
        throw new CommandoError("Expected %s parameter(s), got %s".format(expected, actual));
}


bool checkReturn(bool reset=false){
    if(reset && returnTrigger){
        returnTrigger = false;
        return true;
    }
    return returnTrigger;
}


FunctionReturn run()(auto ref Statement[] statements, auto ref Stack stack, bool remove){
	FunctionReturn result;
    foreach(statement; statements){
        result = statement.run(stack);
        if(checkReturn(remove))
            return stack[returnIndex];
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

