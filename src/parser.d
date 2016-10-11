
module pike.parser;

import pike;


private struct StatementBuild {
	string command;
}

class Parser {

	Statement[] statements;
	string identifier;
	long line;

	dstring statement;

	bool inComment;

	int inBrace;

	bool inBlock;
	int indent;
	int indentCheck;
	bool indentQueried;
	bool indentDone;

	this(string identifier){
		this.identifier = identifier;
	}
 
	void finishStatement(){
		if(statement.strip.length){
			//writeln("statement ", statement);
			if(statement.split.length > 1 && statement.split[1].canFind("="))
				statements ~= new Assignment(statement.to!string, identifier, line);
			else
				statements ~= new Call(statement.to!string, identifier, line);	
		}
		statement = "";
	}

	void parse(string code){

		foreach(i, dchar c; code ~ "\n"){

			//writeln("CHAR ", c);
			if(c == '\n')
				line++;

			if(c == '\n'){
				if(!inComment && !inBlock && !inBrace){
					finishStatement;
				}
				inComment = false;
				if(!inBlock)
					continue;
			}

			if(inComment){
				continue;
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
						//writeln("indent: ", indent);
					}
				}else{
					if(c == '\n'){
						//writeln("c == '\\n'");
						if(indent < 0){
							inBlock = false;
							finishStatement;
						}
						indentCheck = 0;
						indentDone = false;
					}else if(c.isWhite && !indentDone){
						//writeln("c.isWhite && !indentDone");
						indentCheck++;
					}else if(indentCheck < indent){
						//writeln("indentCheck < indent");
						inBlock = false;
						finishStatement;
					}
					if(inBlock && !c.isWhite){
						//writeln("inBlock && !c.isWhite");
						indentDone = true;
					}
				}
			}else if(c == ':'){
				//writeln("started block");
				inBlock = true;
				indent = -1;
				indentCheck = 0;
				indentQueried = false;
				indentDone = false;
			}

			statement ~= c;

			if(i == code.length && statement.length)
				finishStatement;
		}

	}

}
