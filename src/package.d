
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

	commando.util,
	commando.interpreter,
	commando.parser,
	commando.stack,
	commando.statement,
	commando.parameter,
	commando.variable,
	commando.globals.all,
	commando.globals.arithmetic,
	commando.globals.comparison,
	commando.globals.constants,
	commando.globals.container,
	commando.globals.language,
	commando.commandoError;
