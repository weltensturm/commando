
module commando.parser;

import commando;


private enum {
	U, // unary
	B, // binary
}

private enum {
	LTR,
	RTL
}

struct OpGroup {
	int dir;
	int[string] ops;
}

enum operators = [
	/// also is precedence
	OpGroup(LTR, [".": B]),
	OpGroup(LTR, ["*": B, "/": B]),
	OpGroup(LTR, ["+": B, "-": B]),
	OpGroup(LTR, [">=": B, "<=": B, ">": B, "<": B]),
	OpGroup(LTR, ["not": U]),
	OpGroup(LTR, ["and": B, "or": B]),
	OpGroup(LTR, ["==": B, "!=": B]),
	OpGroup(RTL, ["=": B, "~=": B, "+=": B, "-=": B]),
	OpGroup(RTL, ["|": B]),
];


bool isOperator(string haystack){
	foreach(ops; operators){
		if(haystack in ops.ops)
			return true;
	}
	return false;
}


string operatorJoin(string left, string right, string op){
	return "(" ~ op ~ " " ~ left ~ " " ~ right ~ ")";
}

string[] resolveOperators(string[] command){
	debug(Parser){
		DebugHelper.writelni("OP ", command);
	}
	foreach(op; operators){
		auto command_dir = command;
		if(op.dir == RTL)
			command_dir = command.retro.array;
		foreach(i, part; command_dir){
			if(op.dir == RTL)
				i = command.length-1-i;
			if(part in op.ops){
				debug(Parser){
					DebugHelper.writelni("found ", part);
				}
				string[] pre, post;
				if(i == 0 || i+1 >= command.length)
					throw new Exception("");
				if(i > 1)
					pre = command[0..i-1];
				if(i < command.length)
					post = command[i+2..$];
				if(op.ops[part] == U){
					return  resolveOperators(pre ~ [command[i-1]] ~ operatorJoin(command[i+1], "", part) ~ post);
				}else if(op.dir == RTL){
					bool func;
					if(i+1 == command.length-1)
						func = true;
					return [part,
								(i-1 == 0 ? "%s" : "(%s)").format(resolveOperators(command[0..i]).join(" ")),
								    (func ? "%s" : "(%s)").format(resolveOperators(command[i+1..$]).join(" "))
			               ];
				}else{
					return  resolveOperators(pre ~ operatorJoin(command[i-1], command[i+1], part) ~ post);
				}
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
	if(".,*/+-><=~:[]{}".canFind(c))
		return CharType.operator;
	return CharType.text;
}


bool isName(string s){
	return s.all!(a => a.charType == CharType.text && !a.isWhite);
}


class DebugHelper {

	static int level;

	static void writei(Args...)(Args args){
		debug(Parser){
			foreach(_; 0..level)
				.write('\t');
		}
		.write(args);
	}

	static void writelni(Args...)(Args args){
		debug(Parser){
			foreach(_; 0..level)
				.write('\t');
		}
		.writeln(args);
	}

	static void write(Args...)(Args args){
		debug(Parser){
			.write(args);
		}
	}

	static void writeln(Args...)(Args args){
		debug(Parser){
			.writeln(args);
		}
	}

	static void push(){
		debug(Parser){
			writeln;
			level++;
		}
	}

	static void pop(){
		debug(Parser){
			level--;
			writeln;
		}
	}
}


class Indent {

	int[] indent = [0];

	int indentCheck;

	bool indentDone;

	alias Fn = void delegate(size_t);

	void process(dchar c, Fn push, Fn keep, Fn pop){
		if(c == '\n'){
			indentDone = false;
			indentCheck = 0;
		}else if(!indentDone){
			if(c.isWhite){
				indentCheck++;
			}else{
				indentDone = true;
				if(indentCheck == indent[$-1])
					keep(indent.length);
				else if(indentCheck > indent[$-1]){
					indent ~= indentCheck;
					push(indent.length);
				}
				while(indentCheck < indent[$-1]){
					indent = indent[0..$-1];
					pop(indent.length);
				}
			}
		}
	}

	int current(){
		return indent.length.to!int;
	}

}


class Parser {

	Statement[] statements;
	string identifier;
	long line = 1;
	long statementLine;
	string lineText;

	string[] command;

	char[] build;

	CharType currentType = CharType.text;

	bool inComment;
	int inBrace;
	int inBracket;
	bool inString;
	int inFunction;
	bool inPipe;

	Indent indent;
	size_t indentTarget;
	size_t indentBlock;

	this(string identifier, long line=1){
		this.identifier = identifier;
		this.line = line;
		indent = new Indent;
	}

	void finishStatement(){
		finishParam;
		if(command.length){
			debug(Parser){
				DebugHelper.writelni;
				DebugHelper.writelni("[COMMAND ", command, "]");
				DebugHelper.writei;
			}
			if(command.length > 1 && !command[0].isOperator){
				try
					command = command.resolveOperators;
				catch(Exception e)
					throw new CommandoError("%s(%s): Syntax error: missing argument for operator\n\t%s".format(identifier, line, command));
			}
			Parameter[] parameters;
			bool nextIsAssignment;
			bool inIndex;
			foreach(i, part; command){
				if(!part.length)
					continue;
				else if(nextIsAssignment && part.isName){
					parameters ~= new ParameterAssignmentTarget(part.idup);
					nextIsAssignment = false;
				}else if(part.isNumeric)
					parameters ~= new ParameterLiteral(part.to!double);
				else if(part.startsWith("\"") || (inIndex && i > 2))
					parameters ~= new ParameterLiteral(part[1..$-1].idup);
				else if(part.startsWith("(.")){
					parameters ~= new ParameterIndexCall(part[1..$-1].idup, identifier, statementLine);
				}else if(part.startsWith("("))
					parameters ~= new ParameterCall(part[1..$-1].idup, identifier, statementLine);
				else if(part.startsWith(":", "$")){
					auto argsbody = (" " ~ part).split(":");
					if(argsbody.length < 2)
						throw new CommandoError("%s(%s): Syntax error: Function without body\n\t%s"
												.format(identifier, line, command));
					parameters ~= new ParameterFunction(
							part.startsWith("$"),
							argsbody[0].strip.chompPrefix("$").split,
							argsbody[1..$].join(":"),
							identifier,
							statementLine
					);
				}else if(part.startsWith("["))
					parameters ~= new ParameterData(part[1..$-1].idup, identifier, statementLine);
				else {
					if(part == "="){
						if(parameters.length > 0)
							throw new CommandoError("%s(%s): Syntax error: multiple assign targets".format(identifier, line, command));
						nextIsAssignment = true;
					}else if(part == "."){
						inIndex = true;
					}
					parameters ~= new ParameterVariable(part.idup);
				}
			}
			lineText = (lineText.strip ~ "\n").split("\n")[0];
			statements ~= new Statement(parameters, identifier, statementLine, lineText);
			command = [];
		}
		indentTarget = 0;
		indentBlock = 0;
		lineText = "";
		statementLine = 0;
	}

	void finishParam(){
		if(inBrace != 0){
			string desc;
			if(inBrace > 0)
				desc = "%s brace%s not closed".format(inBrace, inBrace > 1 ? "s" : "");
			else
				desc = "too many (%s) closing braces".format(inBrace.abs);
			throw new CommandoError("%s(%s): Syntax error: %s\n\t%s".format(identifier, line, desc, build));
		}
		build = build.strip;
		if(build.length){
			command ~= build.idup;
			DebugHelper.write("[", build.replace("\n", "\\n"), "]");
			build = [];
		}
		inFunction = 0;
	}

	void parse(string code){

		DebugHelper.push;
		DebugHelper.writei;

		foreach(i, dchar c; code ~ "\n"){

			if(c == '\r')
				continue;

			if(c == '\n'){
				line++;
				inComment = false;
			}

			if(inComment){
				continue;
			}

			indent.process(
				c,
				(l){
					DebugHelper.write(" [push=", l, " ", indentTarget, " ", indentBlock, "]");
					if(!command.length)
						indentTarget = l;
				},
				(l){
					if(!inString && !inBrace && l <= indentBlock)
						finishParam;
					if(!inString && !inBrace && l <= indentTarget)
						finishStatement;
					if(!command.length)
						indentTarget = l;
					DebugHelper.write(" [keep=", l, " ", indentTarget, " ", indentBlock, "]");
				},
				(l){
					if(!inString && !inBrace && l <= indentBlock)
						finishParam;
					if(!inString && !inBrace && l <= indentTarget)
						finishStatement;
					if(!command.length)
						indentTarget = l;
					DebugHelper.write(" [pop=", l, " ", indentTarget, " ", indentBlock, "]");
				}
			);

			if(!inString && !inFunction && c == '\"')
				inString = true;
			else if(inString && !inFunction && c == '\"'){
				inString = false;
			}else if(!inString && c == '#'){
				inComment = true;
				continue;
			}else if(!inString && !inBrace && (!inFunction || !build.canFind("\n")) && c == '|'){
				finishParam;
			}else if(!inString && !inBracket && !inFunction && c == '('){
				if(!inBrace)
					finishParam;
				inBrace++;
			}else if(!inString && !inBracket && !inFunction && c == ')'){
				inBrace--;
				if(inBrace < 0)
					throw new CommandoError("%s(%s): Syntax error: brace level is %s".format(identifier, line, inBrace));
			}else if(!inString && !inBrace && !inFunction && c == '['){
				if(!inBracket)
					finishParam;
				inBracket++;
			}else if(!inString && !inBrace && !inFunction && c == ']'){
				inBracket--;
				if(inBracket < 0)
					throw new CommandoError("%s(%s): Syntax error: brace level is %s".format(identifier, line, inBracket));
			}else if(!inString && !inBrace && !inFunction && (c == ':' || c == '$')){
				finishParam;
				inFunction = 1;
				indentBlock = indent.current;
				DebugHelper.write("[block start]");
			}else if(!inString && !inBrace && !inBracket && !inFunction && c == ','){
				finishStatement;
				continue;
			}else if(!inString && !inBrace && !inBracket && !inFunction && c.charType != currentType){
				currentType = c.charType;
				DebugHelper.write("[" ~ currentType.to!string ~ "]");
				finishParam;
			}

			DebugHelper.write(" ", c);
			if(c == '\n')
				DebugHelper.writei;

			if(!lineText.length)
				statementLine = line;

			build ~= c;
			lineText ~= c;

			if(!inString && !inBrace && !inBracket && !inFunction && (c == ')' || c.isWhite || c == '\"')){
				finishParam;
			}

			if(i == code.length)
				finishStatement;
		}
		DebugHelper.pop;

	}

}
