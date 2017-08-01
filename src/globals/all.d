
module commando.globals.all;

import commando;

void replaceWith(Variable a, Variable b){
	a.value = b.value;
	a.type = b.type;
}


void loadBuiltins(Stack stack){
	arithmetic(stack);
	comparison(stack);
	constants(stack);
	container(stack);
	language(stack);
}

void loadEcho(Stack stack){
	//commando.global["__imported"] ~= globals;
	stack["echo"] = Variable((Parameter[] params, Stack stack){
		params.map!(a => a.get(stack).to!string).join(' ').writeln;
		return nothing;
	});
	stack["echoData"] = Variable((Parameter[] params, Stack stack){
		params.each!(a => a.get(stack).printData);
		return nothing;
	});

	import std.datetime;
	stack["profile"] = Variable((Parameter[] params, Stack stack){
		auto fn = params[0].get(stack);
		auto start = Clock.currTime;
		fn([], stack);
		return Variable((Clock.currTime - start).split!"msecs"().msecs / 1000.0);
	});

}
