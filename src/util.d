module commando.util;

import commando;


void checkLength(long expected, long actual){
    if(expected != actual)
        throw new CommandoError("Expected %s parameter(s), got %s".format(expected, actual));
}


Variable[] checkReturn(Stack stack, bool remove=false){
    if(!stack[returnIndex].data.array.length)
        return [];
	Variable[] result;
	foreach(i, a; stack[returnIndex])
		result ~= a;
	if(remove)
		stack[returnIndex] = Variable(Variable.Type.data);
	return result;
}


Variable[] run(Statement[] statements, Stack stack, bool remove){
	Variable[] result;
    foreach(statement; statements){
        auto res = statement.run(stack);
        if(auto a = stack.checkReturn(remove))
            return a;
        result = res;
    }
    return result;
}
