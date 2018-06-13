package misc;

import haxe.unit.TestCase;

class PrivateTests extends TestCase {
	
	function testClass () {
		assertTrue(new Class().getIt().next());
	}
	
	function testNestedClass () {
		var it = new NestedClass().getIt();
		assertEquals("sub", it.next());
		assertTrue(it.next());
	}
	
	#if (!cs && !java) // build failed
	function testAbstract () {
		assertTrue(new Abstract().getIt().next());
	}
	
	function testNestedAbstract () {
		var it = new NestedAbstract().getIt();
		assertEquals("sub", it.next());
		assertTrue(it.next());
	}
	#end
}

@:yield
private class Class {
	
	public function new () {}
	
	public function getIt ():Iterator<Bool> {
		@yield return true;
	}
}

@:yield
private class NestedClass {
	
	public function new () {}
	
	public function getIt ():Iterator<Dynamic> {
		
		function getSubIt ():Iterator<String> {
			@yield return "sub";
		}
		
		@yield return getSubIt().next();
		@yield return true;
	}
}

#if (!cs && !java) // build failed
@:build(yield.parser.Parser.run())
abstract Abstract (Int) {
	
	public inline function new () this = 0;
	
	public inline function getIt ():Iterator<Bool> {
		@yield return true;
	}
}

@:build(yield.parser.Parser.run())
private abstract NestedAbstract (Int) {
	
	public inline function new () this = 0;
	
	public inline function getIt ():Iterator<Dynamic> {
		
		function getSubIt ():Iterator<String> {
			@yield return "sub";
		}
		
		@yield return getSubIt().next();
		@yield return true;
	}
}
#end