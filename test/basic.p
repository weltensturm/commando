

pass = fn a:
    return $a

each a in (range 10): echo $a

each (range 2000):
    echo test with pancakes

    param = fn x:
        echo $x

    param test

    indent = fn a:
        b = pass $a
        inner = fn:
                echo inner worked $a
        inner
        echo sup guys $b
        return $b

    echo (indent aa)

    echo (+ 512.3 2)


num = pass 1

add = fn:
    num = + $num 1


add
echo 1 $num
add
echo 2 $num
add
echo 3 $num
add
echo 4 $num

echo hi (range 200) there

each i in (range 2000):
    echo $i
