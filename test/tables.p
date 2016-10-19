

pass = (fn a:
    return $a)

table party:
    pass 5
    test = 1
    func = (fn:
        echo testfunc)


table test:
    p = $party

each i in $test:
    echo MEMBER $i

echo TEST $test

echo ACCESS $test.p.test
test.p.func


