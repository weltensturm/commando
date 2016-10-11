

Base = class:

	x = 5

	function = fun x:
		echo $x


Child = class Base:
	
	function = fun x:
		echo asdf


instance = Child

instance.x
