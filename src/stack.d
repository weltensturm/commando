
module commando.stack;

import commando;


class Stack {
    PassiveArray!(Variable, 100) stack;
    PassiveArray!(Closure, 10) closures;
    PassiveArray!(Frame, 10) frames;
    string[] names;
    bool precompute = true;
    
    static struct Pos {
        int level;
        int index;
    }
    
    this(){
        stack.data.length = 100;
        closures.expand(1);
        frames ~= new Frame;
    }

    Variable[] push()(Frame frame, Closure closure){
        debug(Stack){
            std.stdio.write('\t'.repeat(closures.length),
                            "frame=",
                            frame.lexicalLevel,
                            " (",
                            frame.localNames[0..frame.parameterCount].join(", "),
                            ") ",
                            frame.localNames[frame.parameterCount..$].join(", "),
                            " {");
            writeln("");
        }
        closures ~= closure;
        frames ~= frame;
        stack.expand(frame.localNames.length);
        return local;
    }

    void push()(Frame frame, Closure closure, Parameter[] params){
        debug(Stack){
            string text = '\t'.repeat(closures.length).to!string ~
                          "frame=" ~
                          frame.lexicalLevel.to!string ~
                          " (";
        }
        stack.allocate(frame.localNames.length);
        foreach(i, p; params){
            stack.data[stack.length+i] = p.get(this);
            debug(Stack){
                text ~= frame.localNames[i] ~ "=" ~ stack.data[stack.length+i].to!string;
                if(i < params.length-1)
                    text ~= ", ";
            }
        }
        stack.length += frame.localNames.length;
        closures ~= closure;
        frames ~= frame;
        debug(Stack){
            writeln(text, ") ", frame.localNames[frame.parameterCount..$].join(", "), " {");
        }
    }

    void pop(){
        stack.length -= frames[$-1].localNames.length;
        closures.pop;
        frames.pop;
        debug(Stack){
            writeln('\t'.repeat(closures.length), "}");
        }
    }

    Variable[] local(){
        return stack[$-frames[$-1].locals.length..$];
    }

    ref Variable opIndex()(auto ref Pos idx){
        debug(Stack){
            auto name = ""; //precompute ? "\"" ~ levelNames[idx.level][idx.index] ~ "\" " : "";
            writeln('\t'.repeat(closures.length),
                    "get ",
                    idx.level == frames[$-1].lexicalLevel
                        ? "local "
                    : idx.level == 0
                        ? "global "
                        : "nonlocal ",
                    name,
                    idx);
        }
        if(idx.level == 0){
            return stack[idx.index];
        }else if(idx.level == frames[$-1].lexicalLevel){
            return local[idx.index];
        }else{
            if(!closures[$-1])
                throw new CommandoError("Accessing nonlocal without closure");
            return closures[$-1][idx];
        }
    }

    Variable opIndex()(string s){
        assert(precompute);
        return this[getIndex(s)];
    }

    void opIndexAssign()(auto ref Variable v, auto ref Pos idx){
        debug(Stack){
            writeln('\t'.repeat(closures.length),
                    idx.level == frames[$-1].lexicalLevel
                        ? "local "
                    : idx.level == 0
                        ? "global "
                        : "nonlocal ",
                    idx.level == frames[$-1].lexicalLevel ? frames[$-1].localNames[idx.index] : idx.index.to!string,
                    " = ",
                    v);
        }
        if(idx.level == 0){
            stack[idx.index] = v;
        }else if(idx.level == frames[$-1].lexicalLevel){
            local[idx.index] = v;
        }else{
            closures[$-1][idx] = v;
        }
    }

    void opIndexAssign()(auto ref Variable v, string name){
        this[ensureIndex(name)] = v;
    }

    void opIndexAssign(T)(auto ref T v, string name){
        this[ensureIndex(name)] = construct(v);
    }

    void delegate(int, int, int)[] onAccess;

    int prepush(void delegate(int from, int level, int index) dg){
        assert(precompute);
        closures.expand(1);
        frames ~= new Frame;
        frames[$-1].lexicalLevel = frames[$-2].lexicalLevel+1;
        names ~= "";
        onAccess ~= dg;
        debug(Stack){
            writeln('\t'.repeat(closures.length-1), "compile frame=", frames[$-1].lexicalLevel, " { ");
        }
        return onAccess.length.to!int;
    }
    
    string[] prepop(){
        assert(precompute);
        frames.pop;
        closures.pop;
        onAccess.length--;
        auto end = names.length - names.retro.countUntil("");
        auto r = names[end..$].dup;
        debug(Stack){
            writeln('\t'.repeat(closures.length), "} ");
        }
        names.length = end-1;
        return r;
    }
    
    Pos register(string name){
        if(names.canFind(name))
            throw new CommandoError("Ambiguous \"%s\"".format(name));
        return ensureIndex(name);
    }

    Pos ensureIndex(string name){
        assert(precompute);
        if(!names.canFind(name)){
            names ~= name;
            stack.expand(1);
            frames[$-1].localNames ~= name;
            frames[$-1].locals.length += 1;
            debug(Stack){
                writeln('\t'.repeat(closures.length), "register \"", name, "\" ", getIndex(name));
            }
        }
        return getIndex(name);
    }

    Pos getIndex(string name){
        assert(precompute);
        foreach(level, names; levelNames.enumerate){
            if(auto i = names.countUntil(name)+1){
                auto pos = Pos(level.to!int, i.to!int-1);
                debug(Stack){
                    writeln('\t'.repeat(closures.length), "access ", pos);
                }
                foreach(dg; onAccess)
                    dg(onAccess.length.to!int, pos.level, pos.index);
                return pos;
            }
        }
        throw new CommandoError("Compiler error: Unknown \"%s\"".format(name));
    }

    string[][] levelNames(){
        return names.split([""]).array;
    }

    void currentNames(void delegate(string[], Pos[]) dg){
        auto names = levelNames[$-1];
        dg(names, names.map!(a => getIndex(a)).array);
    }

    Stack dup(){
        auto a = new Stack;
        a.stack = stack.dup;
        a.names = names.dup;
        return a;
    }

}
