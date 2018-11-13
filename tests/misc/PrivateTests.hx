package misc;

import utest.Assert;

class PrivateTests extends utest.Test {

	function testClass () {
		Assert.isTrue(new Class().getIt().next());
	}
	
	function testNestedClass () {
		var it = new NestedClass().getIt();
		Assert.equals("sub", it.next());
		Assert.isTrue(it.next());
	}
	
	#if (!cs && !java || haxe_ver >= 4.000) // build failed
	function testAbstract () {
		Assert.isTrue(new Abstract().getIt().next());
	}
	
	function testNestedAbstract () {
		var it = new NestedAbstract().getIt();
		Assert.equals("sub", it.next());
		Assert.isTrue(it.next());
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

#if (!cs && !java || haxe_ver >= 4.000) // build failed
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