package misc;

import utest.Assert;
import haxe.Json;

@:yield
class InferenceTests extends utest.Test {
	
	function testFromConsts () {
		var it:Iterator<Dynamic> = fromConsts();
		Assert.isTrue(it.hasNext());
		Assert.equals(3, it.next());
		Assert.equals("", it.next());
		Assert.equals(3.4, it.next());
		Assert.equals(Json.stringify(~/[A-Z]/), Json.stringify(it.next()));
		Assert.isFalse(it.hasNext());
	}
	
	function fromConsts ():Iterator<Dynamic> {
		
		var a = 3;
		@yield return a;
		
		var b = "";
		@yield return b;
		
		var c = 3.4;
		@yield return c;
		
		var d = ~/[A-Z]/;
		@yield return d;
	}
	
	function testFromIdents () {
		var it:Iterator<Dynamic> = fromIdents();
		Assert.isTrue(it.hasNext());
		Assert.equals(3, it.next());
		Assert.equals("", it.next());
		Assert.equals(3.4, it.next());
		Assert.equals(Json.stringify(~/[A-Z]/), Json.stringify(it.next()));
		Assert.isFalse(it.hasNext());
	}
	
	function fromIdents ():Iterator<Dynamic> {
		
		var a:Int;
		var b:String;
		var c:Float;
		var d:EReg;
		
		a = 3;
		var v1 = a;
		@yield return v1;
		
		b = "";
		var v1 = b;
		@yield return v1;
		
		c = 3.4;
		var v1 = c;
		@yield return v1;
		
		d = ~/[A-Z]/;
		var v1 = d;
		@yield return v1;
	}
	
	function testFromIdentsFromConsts () {
		var it:Iterator<Dynamic> = fromIdentsFromConsts();
		Assert.isTrue(it.hasNext());
		Assert.equals(3, it.next());
		Assert.equals("", it.next());
		Assert.equals(3.4, it.next());
		Assert.equals(Json.stringify(~/[A-Z]/), Json.stringify(it.next()));
		Assert.isFalse(it.hasNext());
	}
	
	function fromIdentsFromConsts ():Iterator<Dynamic> {
		
		var a = 3;
		var b = "";
		var c = 3.4;
		var d = ~/[A-Z]/;
		
		var v1 = a;
		@yield return v1;
		
		var v1 = b;
		@yield return v1;
		
		var v1 = c;
		@yield return v1;
		
		var v1 = d;
		@yield return v1;
	}
	
	function testFromArgs () {
		var it:Iterator<Dynamic> = fromArgs(3, "", 3.4, ~/[A-Z]/);
		Assert.isTrue(it.hasNext());
		Assert.equals(3, it.next());
		Assert.equals("", it.next());
		Assert.equals(3.4, it.next());
		Assert.equals(Json.stringify(~/[A-Z]/), Json.stringify(it.next()));
		Assert.isFalse(it.hasNext());
	}
	
	function fromArgs (a:Int, b:String, c:Float, d:EReg):Iterator<Dynamic> {
		
		var v1 = a;
		@yield return v1;
		
		var v1 = b;
		@yield return v1;
		
		var v1 = c;
		@yield return v1;
		
		var v1 = d;
		@yield return v1;
	}
	
	function testFromArgsFromConsts () {
		var it:Iterator<Dynamic> = fromArgsFromConsts();
		Assert.isTrue(it.hasNext());
		Assert.equals(3, it.next());
		Assert.equals("", it.next());
		Assert.equals(3.4, it.next());
		Assert.isFalse(it.hasNext());
	}
	
	function fromArgsFromConsts (a = 3, b = "", c = 3.4):Iterator<Dynamic> {
		
		var v1 = a;
		@yield return v1;
		
		var v1 = b;
		@yield return v1;
		
		var v1 = c;
		@yield return v1;
	}

	function testInferredType () {
		inferredType();
		Assert.isTrue(true);
	}

	function inferredType () {

		var i = 0;
		var len = 4;

		var a:Void->Int = function () return len;
		// var o = {
		// 	a:a
		// };
		function toto () return a();

		@yield return toto();

		// var a:Void->Iterator<String> = function () {
		// 	@yield return i;
		// 	@yield return i*2;
		// };

		// var b:Array<Void->Iterator<String>> = [while (++i < len) {
		// 	function () {
		// 		@yield return i;
		// 		@yield return i*2;
		// 	};
		// }];

	}
	
}