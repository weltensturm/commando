
module commando.stack;

import commando;


struct PassiveArray(T, size_t steps=10) {
    
    T[] data;
    size_t length;
    
    auto ref T opIndex(size_t i){
        assert(i < length);
        return data[i];
    }
    
    size_t opDollar(){
        return length;
    }
    
    void opOpAssign(string op: "~")(auto ref T value){
        if(data.length < length+1)
            data.length += steps;
        data[length] = value;
        length++;
    }
    
    int opApply(int delegate(ref T) dg){
        int result = 0;
        foreach(ref v; data[0..length]){
            result = dg(v);
            if(result)
                break;
        }
        return result;
    }
    
    void pop(){
        assert(length > 0);
        length--;
    }

    PassiveArray dup(){
        return PassiveArray(data.dup, length);
    }

}


class Stack {
    Variable[] stack;
    string[] names;
    //int[] level;
    PassiveArray!int level;
    bool precompute = true;
    
    static struct Pos {
        int level;
        int index;
    }
    
    this(){
        stack.length = 100;
        level ~= 0;
        level ~= 0;
    }

    int index()(auto ref Pos pos){
        return (pos.level < 0 ? level[$-2] : level[pos.level]) + pos.index;
    }

    void push(int length){
        push([], length);
    }

    void push()(auto ref Variable[] vars, int add){
        debug(Stack){
            std.stdio.write('\t'.repeat(level.length), "push ");
            foreach(i, v; vars){
                std.stdio.write(level[$-1]+i, "=", v, " ");
            }
            foreach(i; 0..add){
                std.stdio.write(level[$-1]+i, "=null ");
            }
            writeln("");
        }
        auto end = level[$-1]+vars.length.to!int+add;
        while(end+1 > stack.length)
            stack.length += 100;
        stack[level[$-1] .. end-add] = vars;
        level ~= end;
    }

    void pop(){
        level.length -= 1;
        debug(Stack){
            writeln('\t'.repeat(level.length), "pop");
        }
    }

    void opIndexAssign()(auto ref Variable v, auto ref Pos idx){
        debug(Stack){
            writeln('\t'.repeat(level.length), "set ", idx, "=", index(idx), " ", v);
        }
        stack[index(idx)] = v;
    }

    void opIndexAssign()(auto ref Variable v, string name){
        this[ensureIndex(name)] = v;
    }

    void opIndexAssign(T)(auto ref T v, string name){
        this[ensureIndex(name)] = construct(v);
    }

    Variable opIndex()(auto ref Pos idx){
        debug(Stack){
            writeln('\t'.repeat(level.length), "get ", idx, "=", index(idx), " ", stack[index(idx)]);
        }
        return stack[index(idx)];
    }


    void prepush(){
        assert(precompute);
        level ~= level[$-1];
        debug(Stack){
            writeln('\t'.repeat(level.length-1), "prepush ");
        }
    }
    
    string[] prepop(){
        assert(precompute);
        auto r = names[level[$-2]..$].dup;
        debug(Stack){
            writeln('\t'.repeat(level.length-1), "prepop ", r.map!(a => "%s=%s".format(getIndex(a), a)).join(" "));
        }
        level.pop;
        names.length = level[$-1];
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
            writeln('\t'.repeat(level.length), "register ", name, " ", names.length);
            names ~= name;
            level[$-1] += 1;
        }
        return getIndex(name);
    }

    Pos getIndex(string name){
        assert(precompute);
        foreach(index, names; levelNames.enumerate){
            if(auto i = names.countUntil(name)+1)
                return Pos(
                        index+2==level.length && index != 0 ? -1 : index.to!int,
                        i.to!int-1
                );
        }
        throw new CommandoError("Compiler error: Unknown \"%s\"".format(name));
    }

    string[][] levelNames(){
        string[][] levelNames;
        size_t previous = 0;
        foreach(l; level){
            if(l == 0)
                continue;
            levelNames ~= names[previous .. l];
            previous = l;
        }
        return levelNames;
    }

    void currentNames(void delegate(string[], Pos[]) dg){
        auto names = names[level[$-2] .. level[$-1]];
        dg(names, names.map!(a => getIndex(a)).array);
    }

    Stack dup(){
        auto a = new Stack;
        a.stack = stack.dup;
        a.level = level.dup;
        a.names = names.dup;
        return a;
    }

}
