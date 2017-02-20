
module commando.builtins.all;

import commando;

void replaceWith(Variable a, Variable b){
	a.value = b.value;
	a.type = b.type;
}


void loadBuiltins(Interpreter commando){

	arithmetic(commando);
	comparison(commando);
	constants(commando);
	container(commando);
	language(commando);

}

void loadFn(Interpreter commando){
}

void loadEcho(Interpreter commando){
	auto builtins = commando.global;//.context(commando.global);
	//commando.global["__imported"] ~= builtins;
	builtins["echo"] = new Variable((Parameter[] params, Variable context){
		params.map!(a => a.evaluate(context).to!string).join(' ').writeln;
		return nothing;
	});
}
