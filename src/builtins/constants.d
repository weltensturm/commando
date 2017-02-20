module commando.builtins.constants;

import commando;


void constants(Interpreter commando){
    auto constants = commando.global;

	constants["true"] = new Variable(true);

	constants["false"] = new Variable(false);

	constants["null"] = new Variable;

}
