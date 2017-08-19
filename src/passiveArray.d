module commando.passiveArray;


import std.string;


struct PassiveArray(T, size_t steps=10) {
    
    T[] data;
    size_t length;
    
    auto ref T opIndex(size_t i){
        assert(i < length, "Index %s is out of bounds (length=%s)".format(i, length));
        return data[i];
    }
    
    size_t opDollar(){
        return length;
    }

    auto opSlice(size_t left, size_t right){
        return data[left..right];
    }
    
    void opOpAssign(string op: "~")(auto ref T value){
        if(data.length < length+1)
            data.length += steps;
        data[length] = value;
        length++;
    }
    
    void expand(size_t count){
        allocate(count);
        length += count;
    }

    void allocate(size_t count){
        while(data.length < length+count)
            data.length += steps;
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

