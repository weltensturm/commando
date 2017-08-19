module commando.frame;

import commando;


class Frame {

    size_t lexicalLevel;
    string[] localNames;
    Stack.Pos[] locals;
    Stack.Pos[] nonlocals;
    size_t parameterCount;
    size_t[] captured;

}
