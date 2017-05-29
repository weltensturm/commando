module commando.stack;

import commando;


class Stack {
    Variable[] stack;
    string[] names;
    int[] level;
    bool precompute = true;
    
    static struct Pos {
        int level;
        int index;
    }
    
    int index(Pos pos){
        return pos.level < 0 ? level[$-1]+pos.index : level[pos.level]+pos.index;
    }

    void push(string[] names){
        level ~= stack.length.to!int;
        stack.length += names.length;
        this.names ~= names;
        debug(Stack){
        	writeln('\t'.repeat(level.length-1), "push ", names);
        }
    }

    void push(int length){
        level ~= stack.length.to!int;
        stack.length += names.length;
    }

    void push(string[] names, Variable[] vars){
        level ~= stack.length.to!int;
        stack ~= vars;
        stack.length += names.length-vars.length;
        this.names ~= names;
        debug(Stack){
        	writeln('\t'.repeat(level.length-1), "push ", names, vars);
        }
    }

    void push(Variable[] vars, int add){
        level ~= stack.length.to!int;
        stack ~= vars;
        stack.length += add;
    }

    void pop(){
        stack.length = level[$-1];
        //names.length = level[$-1];
        level = level[0..$-1];
        debug(Stack){
	        writeln('\t'.repeat(level.length), "pop");
        }
    }

    void set(Pos idx, Variable v){
    	debug(Stack){
            writeln("get ", idx);
            writeln('\t'.repeat(level.length), "set ", index(idx), " ", v);
    	}
        stack[index(idx)] = v;
    }

    void set(string name, Variable v){
    	if(precompute)
	    	if(!names.canFind(name))
		    	register(name);
        foreach(i, n; names.enumerate.retro)
            if(n == name){
                set(Pos(0, i.to!int), v);
                return;
            }
        if(!precompute)
	        throw new CommandoError("Unknown \"%s\"".format(name));
    }

    Variable get(Pos idx){
    	debug(Stack){
            writeln(
                '\t'.repeat(level.length), "get ", index(idx), " ", stack[index(idx)]);
    	}
        return stack[index(idx)];
    }

    Variable get(string name){
        foreach(i, n; names.enumerate.retro)
            if(n == name)
                return get(Pos(0, i.to!int));
        throw new CommandoError("Unknown \"%s\"".format(name));
    }

    Variable opIndex(T)(T s){
        return get(s);
    }

    void opIndexAssign(T)(Variable v, T s){
        set(s, v);
    }

    Pos register(string name){
        assert(precompute);
    	if(names.canFind(name))
	    	throw new CommandoError("Ambiguous \"%s\"".format(name));
        names ~= name;
        stack.length = names.length;
        return getIndex(name);
    }

	void prepush(){
		assert(precompute);
        level ~= names.length.to!int;
        debug(Stack){
        	writeln('\t'.repeat(level.length-1), "prepush ");
        }
	}
	
	string[] prepop(){
		assert(precompute);
        auto r = names[level[$-1]..$].dup;
        debug(Stack){
            auto idx = level[$-1];
        	writeln('\t'.repeat(level.length-1), "prepop ", r.map!(a => "%s=%s".format(getIndex(a), a)).join(" "));
        }
        names.length = level[$-1];
        stack.length = level[$-1];
        level = level[0..$-1];
        return r;
	}
	
    Pos getIndex(string name){
        assert(precompute);
        foreach(levelI, l; level.enumerate.retro){
            if(auto i = names[level[levelI]..$].countUntil(name)+1)
                return Pos(levelI != level.length-1 || levelI == 0 ? levelI : -1, i-1);
        }
        throw new CommandoError("Compiler error: Unknown \"%s\"".format(name));
    }

	Pos ensureIndex(string name){
        assert(precompute);
		if(!names.canFind(name)){
			names ~= name;
			stack.length += 1;
		}
		return getIndex(name);
	}

    Stack dup(){
        auto a = new Stack;
        a.stack = stack.dup;
        a.level = level.dup;
        a.names = names.dup;
        return a;
    }

}
