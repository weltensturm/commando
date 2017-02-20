
module commando.parser;

import commando;


enum operators = [
	/// Binary for now, this also is precedence
	["."],
	["*", "/"],
	["+", "-"],
	[">=", "<=", ">", "<"],
	["and", "or"],
	["=="],
	[":"],
	["="]
];


string operatorJoin(string left, string right, string op){
	return "(" ~ op ~ " " ~ left ~ " " ~ right ~ ")";
}

string[] resolveOperators(string[] command, size_t level=0){
	foreach(op; operators){
		foreach(i, part; command){
			if(op.canFind(part)){
				string[] pre, post;
				if(i == 0 || i+1 >= command.length)
					throw new Exception("");
				if(i > 1)
					pre = command[0..i-1];
				if(i < command.length)
					post = command[i+2..$];
				if(part != "=")
					return  resolveOperators(pre ~ operatorJoin(command[i-1], command[i+1], part) ~ post, level+1);
				else
					return  ["=", command[i-1]] ~ ["(" ~ resolveOperators([command[i+1]] ~ post).join(" ") ~ ")"];
			}
		}
	}
	return command;
}

enum CharType {
	operator,
	text
}

CharType charType(dchar c){
	if(".*/+-><=:".canFind(c))
		return CharType.operator;
	return CharType.text;
}

class Parser {

	Statement[] statements;
	string identifier;
	long line;
	long lineBlock;

	string[] command;

	char[] build;

	CharType currentType = CharType.text;

	bool inComment;

	int inBrace;

	bool inString;

	bool inBlock;
	int indent;
	int indentCheck;
	bool indentQueried;
	bool indentDone;

	this(string identifier, long line=0){
		this.identifier = identifier;
		this.line = line;
	}

	void finishStatement(){
		finishParam;
		if(command.length){
			if(command.length > 1){
				if(!operators.reduce!((a, b) => a ~ b).canFind(command[0])){
					try
						command = command.resolveOperators;
					catch(Exception e)
						throw new CommandoError("%s(%s): Syntax error: missing argument for operator\n\t%s".format(identifier, line, command));
				}
			}
			//writeln("COMMAND ", command);
			Parameter[] parameters;
			foreach(part; command){
				if(!part.length)
					continue;
				else if(part.isNumeric)
					parameters ~= new ParameterLiteral(part.to!double);
				else if(part.startsWith("\""))
					parameters ~= new ParameterLiteral(part[1..$-1].idup);
				else if(part.startsWith("("))
					parameters ~= new ParameterCall(part[1..$-1].idup, identifier, line-lineBlock);
				else if(part.startsWith(":"))
					parameters ~= new ParameterBlock(part[1..$].idup, identifier, line-lineBlock);
				else
					parameters ~= new ParameterVariable(part.idup);
			}
			statements ~= new Statement(parameters, identifier, line-lineBlock);
			command = [];
		}
		inBlock = false;
		lineBlock = 0;
	}

	void finishParam(){
		if(inBrace != 0)
			throw new CommandoError("%s(%s): Syntax error: brace level is %s\n\t%s".format(identifier, line, inBrace, build));
		build = build.strip;
		if(build.length){
			command ~= build.idup;
			//writeln("PARAM ", build);
			build = [];
		}
	}

	void parse(string code){

		foreach(i, dchar c; code ~ "\n"){

			if(c == '\n'){
				line++;
				if(inBlock || inBrace)
					lineBlock++;
				if(!inComment && !inBlock && !inBrace){
					finishStatement;
				}
				inComment = false;
			}

			if(inComment){
				continue;
			}

			if(!inString && !inBlock && c == '('){
				if(!inBrace)
					finishParam;
				inBrace++;
			}

			if(!inString && !inBlock && c == ')'){
				inBrace--;
			}

			if(!inString && !inBlock && c == '\"')
				inString = true;
			else if(inString && !inBlock && c == '\"'){
				inString = false;
			}

			if(!inString && c == '#'){
				inComment = true;
				continue;
			}

			if(inBlock){
				if(!indentQueried){
					if(c == '\n'){
						indent = 0;
					}else if(c.isWhite && indent >= 0){
						indent++;
					}else if(!c.isWhite){
						indentQueried = true;
						indentDone = true;
						indentCheck = indent;
					}
				}else{
					if(c == '\n'){
						if(indent < 0){
							lineBlock--;
							finishStatement;
						}
						indentCheck = 0;
						indentDone = false;
					}else if(c.isWhite && !indentDone){
						indentCheck++;
					}else if(indentCheck < indent){
						lineBlock--;
						finishStatement;
					}
					if(inBlock && !c.isWhite)
						indentDone = true;
				}
			}else if(c == ':' && !inString && !inBrace){
				inBlock = true;
				indent = -1;
				indentCheck = 0;
				indentQueried = false;
				indentDone = false;
				finishParam;
			}

			if(!inString && !inBrace && !inBlock && c.charType != currentType){
				currentType = c.charType;
				finishParam;
			}

			build ~= c;

			if(!inString && !inBrace && !inBlock && (c == ')' || c.isWhite || c == '\"')){
				finishParam;
			}

			if(i == code.length)
				finishStatement;
		}

	}

}
