package eparsers;

import haxe.unit.TestCase;
import yield.Yield;

class EFunctionTests extends TestCase implements Yield
{
	private static var NULL_INT:Int;

	public function new () {
		super();
		var n:Null<Int> = null;
		NULL_INT = n;
	}
	
	function testFunDeclaration () {
		var it:Iterator<Dynamic> = cast funDeclaration();
		
		assertEquals(4, it.next());
		assertEquals(4, it.next());
		assertEquals(5, it.next());
		assertEquals(10, it.next());
		assertEquals(30, it.next());
		assertEquals(30, it.next());
	}
	
	function funDeclaration ():Iterator<Int> {
		function a () { return 3; }
		function a () { return 4; }
		@yield return a();
		@yield return a();
		var b = function ():Int { return a() + 1; };
		@yield return b();
		@yield return b() + a() + 1;
		var c:Void->Int = function d () { return b() + b() + a() + 1; };
		@yield return c() + d();
		@yield return c() + d();
	}
	
	
	function testSimpleFunc () {
		var it:Iterator<Dynamic> = cast simpleFunc();
		
		assertEquals(5, it.next());
		assertEquals(15, it.next());
	}
	
	#if (neko || js || php || python || lua)
	function simpleFunc ():Iterator<Int> {
		
		function a () {
			return 5;
		}
		
		@yield return a();
		
		function b () {
			return a() + 5;
		}
		var b = function c () {
			return a() + b();
		}
		
		@yield return b();
	}
	#else
	function simpleFunc ():Iterator<Int> {
		
		function a () {
			return 5;
		}
		
		@yield return a();
		
		function b () {
			return a() + 5;
		}
		var b:Void->Int = function c () {
			return a() + b();
		}
		
		@yield return b();
	}
	#end
	
	
	function testConditional () {
		var it:Iterator<Dynamic> = cast conditional();
		
		assertEquals(2, it.next());
		assertEquals(16, it.next());
		assertEquals(32, it.next());
	}
	
	#if (neko || js || php || python || lua)
	function conditional ():Iterator<Int> {
		
		var condition:Bool = true;
		
		var a;
		
		if (condition) {
			a = function () {return 2; };
		} else {
			a = function () {return 4; };
		}
		
		@yield return a();
		
		var b = !condition ? function () {return 8; } : function () {return 16; };
		
		@yield return b();
		@yield return (condition ? function() {return 32; } : function() {return 64; })();
		
	}
	#else
	function conditional ():Iterator<Int> {
		
		var condition:Bool = true;
		
		var a:Void->Int;
		
		if (condition) {
			a = function () {return 2; };
		} else {
			a = function () {return 4; };
		}
		
		@yield return a();
		
		var b:Void->Int = !condition ? function () {return 8; } : function () {return 16; };
		
		@yield return b();
		@yield return (condition ? function() {return 32; } : function() {return 64; })();
		
	}
	#end
	
	
	function testNestedYield () {
		var it:Iterator<Dynamic> = cast nestedYield();
		
		assertEquals(0, it.next());
		assertEquals(5, it.next());
		assertEquals(6, it.next());
		assertEquals(64, it.next());
	}
	
	function nestedYield ():Iterator<Int> {
		
		function a ():Iterator<Int> {
			@yield return 5;
			var condition = false;
			@yield return 6;
			@yield return (condition ? function() {return 32; } : function() {return 64; })();
		}
		
		@yield return 0;
		
		var aIterator:Iterator<Dynamic> = cast a();
		
		
		@yield return aIterator.next();
		@yield return aIterator.next();
		@yield return aIterator.next();
		
	}
	
	
	function testArgs () {
		var it = args(true);
		
		assertEquals(4, it.next());
		assertEquals(0, it.next());
		assertFalse(it.hasNext());
		
		it = args(false);
		
		assertEquals(8, it.next());
		assertFalse(it.hasNext());
	}
	
	#if (neko || js || php || python || lua)
	function args (shouldYieldReturn):Iterator<Dynamic> {
		
		var a = 0;
		
		if (shouldYieldReturn) {
			@yield return 4;
		} else {
			a = 8;
		}
		
		@yield return a;
	}
	#else
	function args (shouldYieldReturn:Bool):Iterator<Dynamic> {
		
		var a = 0;
		
		if (shouldYieldReturn) {
			@yield return 4;
		} else {
			a = 8;
		}
		
		@yield return a;
	}
	#end
	
	
	function testNestedArgs () {
		var it:Iterator<Dynamic> = cast nestedArgs(false);
		
		assertEquals(0, it.next());
		assertEquals(5, it.next());
		assertEquals(64, it.next());
		assertFalse(it.next());
		assertFalse(it.next());
		
		assertFalse(it.hasNext());
	}
	
	#if (neko || js || php || python || lua)
	function nestedArgs (condition):Iterator<Dynamic> {
		
		function a (foo = "bar"):Iterator<Dynamic> {
			
			@yield return foo == "bar" ? 5 : 10;
			
			@yield return (condition ? function(arg) {return 32; } : function(arg) { 
				
				var condition = condition;
				
				if (!condition && foo == "bar") {
					condition = true;
				}
				
				return condition ? 64 : 33;
				
			})(true);
			
			@yield return condition;
		}
		
		@yield return 0;
		
		var aIterator:Iterator<Dynamic> = cast a();
		
		
		@yield return aIterator.next();
		@yield return aIterator.next();
		@yield return aIterator.next();
		@yield return aIterator.hasNext();
	}
	#else
	function nestedArgs (condition:Bool):Iterator<Dynamic> {
		
		function a (foo = "bar"):Iterator<Dynamic> {
			
			@yield return foo == "bar" ? 5 : 10;
			
			@yield return (condition ? cast function(arg:Dynamic) {return 32; } : function(arg:Dynamic) { 
				
				var condition:Bool = condition;
				
				if (!condition && foo == "bar") {
					condition = true;
				}
				
				return condition ? 64 : 33;
				
			})(true);
			
			@yield return condition;
		}
		
		@yield return 0;
		
		var aIterator:Iterator<Dynamic> = cast a();
		
		
		@yield return aIterator.next();
		@yield return aIterator.next();
		@yield return aIterator.next();
		@yield return aIterator.hasNext();
	}
	#end
	
	
	function testNestedArgs2 () {
		var it:Iterator<Dynamic> = cast nestedArgs2(false);
		
		assertEquals("bar", it.next());
		assertEquals("bar", it.next());
		assertEquals("foo", it.next());
		assertEquals("", it.next());
		
	}
	
	#if (neko || js || php || python || lua)
	function nestedArgs2 (condition):Iterator<String> {
	#else
	function nestedArgs2 (condition:Bool):Iterator<String> {
	#end
		
		var foo = "";
		
		function a (a = "bar") {
			return a;
		}
		
		@yield return a();
		
		function b () {
			var foo = "oof";
			return a();
		}
		
		@yield return b();
		
		#if (neko || js || php || python || lua)
		function c (foo) {
			foo = "foo";
			function d (foo) {
				foo = "super fail";
			}
			d("");
			return foo;
		}
		#else
		function c (foo:String) {
			foo = "foo";
			function d (foo:String) {
				foo = "super fail";
			}
			d("");
			return foo;
		}
		#end
		
		@yield return c("");
		@yield return foo;
	}
	
	function testAnonymous () {
		var it:Iterator<Dynamic> = cast anonymous();
		
		assertEquals("foo", it.next());
		assertEquals("bar", it.next());
		assertEquals("", it.next());
		
	}
	
	function anonymous ():Iterator<String> {
		
		var foo = "";
		
		#if (neko || js || php || python || lua)
		var a = function (a = "foo") {
			return a;
		};
		#else
		var a = function (a = "foo"):String {
			return a;
		};
		#end
		
		@yield return a();
		
		@yield return (function(){
			var foo = "bar";
			return a(foo);
		})();
		
		@yield return foo;
	}
	
	
	function testAnonymousYield () {
		var it:Iterator<Dynamic> = cast anonymousYield(false);
		
		assertEquals(5, it.next());
		assertEquals(64, it.next());
		assertFalse(it.next());
		assertFalse(it.next());
		
		assertFalse(it.hasNext());
	}
	
	#if (neko || js || php || python || lua)
	function anonymousYield (condition): Iterator<Dynamic> {
	#else
	function anonymousYield (condition:Bool): Iterator<Dynamic> {
	#end
		
		var a = function (foo = "bar"): Iterator<Dynamic> {
			
			@yield return foo == "bar" ? 5 : 10;
			
			#if (neko || js || php || python || lua)
			@yield return (condition ? function(arg):Dynamic {@yield return 32; } : function(arg):Dynamic { 
			#else
			@yield return (condition ? function(arg:Dynamic):Dynamic {@yield return 32; } : function(arg:Dynamic):Dynamic { 
			#end
				
				var condition:Bool = condition;
				
				if (!condition && foo == "bar") {
					condition = true;
				}
				
				@yield return condition ? 64 : 33;
				
			})(true).next();
			
			@yield return condition;
		};
		
		var aIterator:Iterator<Dynamic> = cast a();
		
		
		@yield return aIterator.next();
		@yield return aIterator.next();
		@yield return aIterator.next();
		@yield return aIterator.hasNext();
	}
	
	function testNestedFunction() {
		
		assertEquals(15, nestedFunction());
	}
	
	function nestedFunction () {
		
		function getIterator (): Iterator<Int> {
			@yield return 1;
			@yield return 2;
			@yield return 4;
			@yield return 8;
		}
		
		var it:Iterator<Int> = getIterator();
		var some:Int = 0;
		
		if (!it.hasNext()) return 100;
		some += it.next();
		if (!it.hasNext()) return 101;
		some += it.next();
		if (!it.hasNext()) return 102;
		some += it.next();
		if (!it.hasNext()) return 103;
		some += it.next();
		
		if (it.hasNext()) return 200;
		return some;
	}
	
	function nestedFunction2 () {
		
		var one:Int = 1;
		
		function deep () {
			
			function getIterator (): Iterator<Dynamic> {
				@yield return one;
				@yield return 2;
				@yield return 4;
				@yield return 8;
			}
		}
	}
	
	function testInitialization () {
		var it = initialization();
		assertTrue(it.hasNext());
		assertEquals(NULL_INT, it.next());
		assertFalse(it.hasNext());
	}
	
	function initialization () {
		
		var v:Int;
		
		function f () {
			v = 3;
		}
		
		@yield return v;
	}
	
	function testInlining () {
		var it = inlining();
		assertEquals(0, it.next());
		assertEquals(3, it.next());
		try {
			it.next();
			assertTrue(false);
		} catch (err:Dynamic) {
			assertTrue(true);
		}
	}
	
	function inlining ():Iterator<Int> {
		
		inline function foo () return 3;
		
		@yield return 0;
		
		@yield return foo();
		
		@yield return untyped foo();
	}
}