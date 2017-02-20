
module commando.parameter;

import commando;


class Parameter {
	Variable evaluate(Variable context){ assert(0); }
	string text(Variable){ assert(0); }
	string statement;
}


class ParameterLiteral: Parameter {

	Variable variable;

	this(double literal){
		variable = new Variable(literal);
	}

	this(string literal){
		variable = new Variable(literal);
	}

	override Variable evaluate(Variable context){
		return variable;
	}

	override string text(Variable){
		return variable.text;
	}
}


class ParameterVariable: Parameter {

	string name;

	this(string name){
		statement = name;
		this.name = name;
	}

	override Variable evaluate(Variable context){
		return context[name];
	}

	override string text(Variable){
		return name;
	}

}

class ParameterCall: Parameter {

	Statement[] statements;

	string identifier;
	long line;

	this(string statement, string identifier, long line){
		this.statement = statement;
		this.identifier = identifier;
		this.line = line;
		auto parser = new Parser(identifier, line);
		parser.parse(statement);
		statements = parser.statements;
	}

	override Variable evaluate(Variable context){
		context = commando.context(context);
		Variable return_;
		context["return"] = (Parameter[] params, Variable context){
			if(params.length > 1)
				throw new CommandoError("Cannot return multiple from brace, " ~ identifier);
			else if(params.length > 0)
				return_ = params[0].evaluate(context);
			else
				return_ = new Variable;
			return nothing;
		};
		Variable last;
		foreach(statement; statements){
			auto tmp = statement.run(context);
			if(tmp.length)
				last = tmp[0];
			if(return_)
				return return_;
		}
		return last;
	}

	override string text(Variable context){
		return evaluate(context).text;
	}

}

class ParameterBlock: Parameter {

	Variable variable;

	string identifier;

	this(string block, string identifier, long line){
		statement = block;
		auto parser = new Parser(identifier, line);
		parser.parse(block);
		variable = new Variable;
		variable.type = Variable.Type.block;
		variable.value.block = parser.statements;
	}

	override Variable evaluate(Variable){
		return variable;
	}

}
