module pike.pikeError;


import pike;


class PikeError: Exception {

    PikeError parent;
    Context context;

    this(string error){
        super(error);
    }

    this(string error, Context context, PikeError parent){
        this.parent = parent;
        this.context = context;
        super(error);
    }

    override string toString(){
        if(parent)
            return parent.toString ~ "\n" ~ msg;
        return msg;
    }

    Context parentContext(){
        auto p = this;
        while(p.parent && p.parent.context)
            p = p.parent;
        return p.context;
    }

}
