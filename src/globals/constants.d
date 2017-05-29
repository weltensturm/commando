module commando.globals.constants;

import commando;


void constants(Stack stack){
	stack["true"] = Variable(true);

	stack["false"] = Variable(false);

	stack["null"] = Variable(Variable.Type.null_);

}
