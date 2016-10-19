
module pike.parameter;

import pike;


class Parameter {
    Variable evaluate(Interpreter pike, Context context){ assert(0); }
}

class ParameterLiteral: Parameter {
    string literal;
    bool number;
    
    this(string literal){
        this.literal = literal;
        number = literal.isNumeric;
    }

    override Variable evaluate(Interpreter pike, Context context){
        if(number)
            return new Variable(literal.to!double);
        else
            return new Variable(literal);
    }
}

class ParameterVariable: Parameter {

    string name;

    this(string name){
        this.name = name;
    }

    override Variable evaluate(Interpreter pike, Context context){
        return context.get(name);
    }

}

class ParameterCall: Parameter {

    Statement[] statements;

    string identifier;

    this(string statement, string identifier, long line){
        writeln("PARAM CALL ", identifier, ' ', line);
        this.identifier = identifier;
        auto parser = new Parser(identifier, line);
        parser.parse(statement);
        statements = parser.statements;
    }

    override Variable evaluate(Interpreter pike, Context context){
        context = new Context(identifier, context);
        Variable ret;
        foreach(statement; statements){
            auto res = statement.run(pike, context);
            if(res.length)
                ret = res[0];
            if("return" in context.variables)
                return context.variables["return"];
        }
        return ret;
    }

}

class ParameterBlock: Parameter {

    Variable variable;

    string identifier;

    this(string block, string identifier, long line){
        writeln("PARAM BLOCK ", identifier, ' ', line);
        auto parser = new Parser(identifier, line);
        parser.parse(block);
        variable = new Variable;
        variable.type = Variable.Type.block;
        variable.value.block = parser.statements;
    }

    override Variable evaluate(Interpreter, Context){
        return variable;
    }

}

