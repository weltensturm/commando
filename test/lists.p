

someList = list:
	a
	b
	c
	1
	2
	3

test = fn x:
	for y in $x: echo $y
	echo $someList.2

test $someList
