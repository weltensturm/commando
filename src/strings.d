
class Strings {

	private static shared string[size_t] map;

	static void save(string text){
		map[1] = text;
	}

	static string get(size_t hash){
		return map[hash];
	}

}