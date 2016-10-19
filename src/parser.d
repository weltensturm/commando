
module pike.parser;

import pike;


enum operators = ["=", "+", "-"];


class Parser {

	Statement[] statements;
	string identifier;
	long line;
	long lineBlock;

	string[] command;

	char[] build;

	bool inComment;

	int inBrace;

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
			if(command.length > 1 && operators.canFind(command[1]))
				command = [command[1]] ~ command[0] ~ command[2..$];
			Parameter[] parameters;
			foreach(part; command[1..$]){
				if(part.startsWith("$"))
					parameters ~= new ParameterVariable(part[1..$].idup);
				else if(part.startsWith("("))
					parameters ~= new ParameterCall(part[1..$-1].idup, identifier, line-lineBlock);
				else if(part.startsWith(":"))
					parameters ~= new ParameterBlock(part[1..$].idup, identifier, line-lineBlock);
				else
					parameters ~= new ParameterLiteral(part.idup);
			}
			statements ~= new Statement(command[0], parameters, identifier, line-lineBlock);
			command = [];
		}
		inBlock = false;
		lineBlock = 0;
	}

	void finishParam(){
		if(inBrace != 0)
			throw new PikeError("%s(%s): Syntax error: brace level is %s".format(identifier, line, inBrace));
		build = build.strip;
		if(build.length){
			command ~= build.idup;
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

			if(!inBlock && c == '('){
				if(!inBrace)
					finishParam;
				inBrace++;
			}

			if(!inBlock && c == ')'){
				inBrace--;
			}

			if(c == '#'){
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
			}else if(c == ':' && !inBrace){
				inBlock = true;
				indent = -1;
				indentCheck = 0;
				indentQueried = false;
				indentDone = false;
				finishParam;
			}

			build ~= c;

			if((c == ')' || c.isWhite) && !inBrace && !inBlock){
				finishParam;
			}

			if(i == code.length)
				finishStatement;
		}

	}

}
