
module commando;

public import

	std.file,
	std.uni,
	std.math,
	std.array,
	std.string,
	std.algorithm,
	std.stdio,
	std.conv,
	std.traits,
	std.functional,
	std.typecons,
	std.range,

	commando.interpreter,
	commando.parser,
	commando.statement,
	commando.parameter,
	commando.context,
	commando.variable,
	commando.builtins.all,
	commando.builtins.arithmetic,
	commando.builtins.comparison,
	commando.builtins.constants,
	commando.builtins.container,
	commando.builtins.language,
	commando.commandoError;
