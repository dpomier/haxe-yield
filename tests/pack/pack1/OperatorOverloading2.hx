package pack.pack1;
import yield.parser.Parser;

#if (!cs && !java) // error CS1004 repeated modifier
@:build(yield.parser.Parser.run())
abstract OperatorOverloading2(String) {
	public inline function new(s:String) {
		this = s;
	}
	
	@:op(A / B)
	public function devide(rhs:Int):Iterator<OperatorOverloading2> {
		
		var len:Int = Math.floor(this.length / rhs);
		
		var i:Int = 0;
		
		for (i in 0...rhs) {
			@yield return new OperatorOverloading2(this.substr(i, len));
			i += len;
		}
		
		@yield break;
	}
}
#end