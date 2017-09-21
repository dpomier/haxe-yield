package misc;

import haxe.unit.TestCase;
import pack.pack2.MiscYielded;
import yield.Yield;

@:yield
class YieldTests extends TestCase
{

	public function new() 
	{
		super();
	}
	
	function testSimpleSplit () {
		var it:Iterator<Dynamic> = cast simpleSplit();
		
		assertEquals(1, it.next());
		assertEquals(2, it.next());
		assertEquals(4, it.next());
		assertFalse(it.hasNext());
	}
	
	function simpleSplit (): Iterator<Int> {
		@yield return 1;
		@yield return 2;
		@yield return 4;
	}
	
	function testStaticVar () {
		var it = staticVar();
		assertTrue(it.hasNext());
		assertEquals(0, it.next());
		assertEquals(1, it.next());
		assertEquals(2, it.next());
		assertFalse(it.hasNext());
	}
	
	static var staticVar:Void->Iterator<Int> = function ():Iterator<Int> {
		
		for (i in 0...3) {
			@yield return i;
		}
	};
	
	function testMember () {
		var it = this.member();
		assertTrue(it.hasNext());
		assertEquals(0, it.next());
		assertEquals(1, it.next());
		assertEquals(2, it.next());
		assertFalse(it.hasNext());
	}
	
	var member:Void->Iterator<Int> = function ():Iterator<Int> {
		
		for (i in 0...3) {
			@yield return i;
		}
	};
	
	function testStaticProperty () {
		var it = staticProperty();
		assertTrue(it.hasNext());
		assertEquals(0, it.next());
		assertEquals(1, it.next());
		assertEquals(2, it.next());
		assertFalse(it.hasNext());
	}
	
	static var staticProperty(default, null) = function () {
		
		for (i in 0...3) {
			@yield return i;
		}
	};
	
	function testProperty () {
		var it = this.propertyMember();
		assertTrue(it.hasNext());
		assertEquals(0, it.next());
		assertEquals(1, it.next());
		assertEquals(2, it.next());
		assertFalse(it.hasNext());
	}
	
	var propertyMember(default, null) = function () {
		
		for (i in 0...3) {
			@yield return i;
		}
	};
	
	function testVarDeclaration () {
		var it:Iterator<Dynamic> = cast varDeclaration();
		
		assertEquals(1, it.next());
		assertEquals(2, it.next());
		assertEquals(4, it.next());
		assertFalse(it.hasNext());
	}
	
	function varDeclaration (): Iterator<Int> {
		var a = 1;
		var a = 1;
		@yield return a;
		var b:Int = a + 1;
		@yield return b;
		@yield return b+a+1;
	}
	
	function testOneLine () {
		var it:Iterator<Dynamic> = cast oneLine();
		
		assertEquals(72, it.next());
		assertFalse(it.hasNext());
	}
	
	function oneLine (): Iterator<Int> @yield return 72;
	
	function testSimpleBreak () {
		var it = simpleBreak(5);
		
		assertTrue(it.hasNext());
		assertEquals(1, it.next());
		assertEquals(2, it.next());
		assertEquals(3, it.next());
		assertEquals(4, it.next());
		assertEquals(5, it.next());
		assertFalse(it.hasNext());
	}
	
	function simpleBreak (value:Int) {
		var i = 0;
		while (true) {
			if (i >= value) {
				@yield break;
			}
			i += 1;
			@yield return i;
		}
		@yield return -1;
		@yield return -1;
	}
	
	function testInlineMethods () {
		var it = inlineMethod1();
		
		assertTrue(it.hasNext());
		assertEquals(1, it.next());
		assertEquals(2, it.next());
		assertEquals(3, it.next());
		assertFalse(it.hasNext());
	}
	
	static inline function inlineMethod1 () {
		@yield return 1;
		@yield return 2;
		@yield return 3;
	}
	
	function testInlineCrossModuleAccess () {
		var it = MiscYielded.inlineMethod2("hello");
		
		assertTrue(it.hasNext());
		assertEquals("hello1", it.next());
		assertEquals("hello2", it.next());
		assertEquals("hello3", it.next());
		assertFalse(it.hasNext());
	}
	
	function testCheckType () {
		
		var a:Int = 3;
		
		var d = (a:Int);
		
		assertTrue(true);
	}
	
	function checkType () {
		
		var a:Int = 3;
		
		var d:Int = (a:Int);
		
		@yield return null;
	}
	
	function func1 ():Iterator<Int> {
		
		function titi () {
			@yield return "hello";
		}
		
		#if (neko || js || php || python || lua)
		var tutu = function ruru () {};
		#else
		var tutu:Void->Void = function ruru () {};
		#end
		
		#if (neko || js || php || python || lua)
		var lulu = (function nunu () {});
		#else
		var lulu:Void->Void = (function nunu () {});
		#end
		
		@yield return 3;
	}
	
	function func2 () {
		
		var thisVar = (function myFunc () {});
		var condition:Bool = true;
		return (!condition ? function() {return 8; } : function() {return 16; })();
		
	}
	
	var property (get, set) :Iterator<String>;
	
	function get_property () {
		
		@yield return "one";
		@yield return "two";
		@yield return "three";
	}
	
	function set_property (v:Iterator<String>) {
		return null;
	}
	
	function testAnonymFor () {
		
		var res:Bool = false;
		
		for (i in (function ():Iterator<Bool> { @yield return true; })()) {
			res = i;
		}
		
		assertTrue(res);
	}
	
	function testAnonymSwitch () {
		
		var res:Bool = false;
		
		switch (3)  {
			
			case 3 if ((function(){
				@yield return 3;
			})().next() == 3):
				
				res = true;
				
			case 3:
			default:
		}
		
		assertTrue(res);
	}
	
	function testAnonymIf () {
		
		var res:Bool = false;
		
		if ((function(){
				@yield return 3;
			})().next() == 3) {
				
				res = true;
			}
			
		assertTrue(res);
	}
	
	function testAnonymWhile () {
		
		var res:Bool = false;
		
		while (!res && (function(){
				@yield return 3;
			})().next() == 3) {
				
				res = true;
			}
			
		assertTrue(res);
	}
	
}