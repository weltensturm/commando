module commando.globals.arithmetic;

import commando;


void arithmetic(Stack stack){

	stack["+"] = (double a, double b) => a+b;

	stack["-"] = (double a, double b) => a-b;

	stack["*"] = (double a, double b) => a*b;

	stack["/"] = (double a, double b) => a/b;

	stack["+="] = Variable((Parameter[] params, Stack stack){
		checkLength(2, params.length);
		auto r = Variable(params[0].get(stack).number + params[1].get(stack).number);
		params[0].set(stack, r);
		return r;
	});

	stack["-="] = Variable((Parameter[] params, Stack stack){
		auto r = Variable(params[0].get(stack).number - params[1].get(stack).number);
		params[0].set(stack, r);
		return r;
	});


}
