package options;

import haxe.unit.TestCase;

class ExplicitTests extends TestCase {
	
	function testShort () {
		var it = new Short().getIt();
		assertTrue(it.next());
	}
	
	function testNormal () {
		var it = new Normal().getIt();
		assertTrue(it.next());
	}
	
	function testFull () {
		var it = new Full().getIt();
		assertTrue(it.next());
	}
	
	function testArgTrue () {
		assertTrue(new ArgTrue().getExplicitIt().next());
	}
	
	function testArgFalse () {
		assertTrue(new ArgFalse().getExplicitIt().next());
		assertTrue(new ArgFalse().getNoExplicitIt().next());
	}
	
	function testParent () {
		assertTrue(new Parent().getParentIt().next());
		assertTrue(new Child().getChildIt().next());
	}
	
	function testIgnoredParent () {
		assertTrue(new Parent().getParentIt().next());
		assertTrue(new Child().getChildIt().next());
	}
	
}

@:yield(Explicit)
private class Short {
	
	public function new () {}
	
	public function getIt ():Iterator<Bool> {
		@yield return true;
	}
}

@:yield(YieldOption.Explicit)
private class Normal {
	
	public function new () {}
	
	public function getIt ():Iterator<Bool> {
		@yield return true;
	}
	
}

@:yield(yield.YieldOption.Explicit)
private class Full {
	
	public function new () {}
	
	public function getIt ():Iterator<Bool> {
		@yield return true;
	}
	
}

@:yield(Explicit(true))
private class ArgTrue {
	
	public function new () {}
	
	public function getExplicitIt ():Iterator<Bool> {
		@yield return true;
	}
}

@:yield(Explicit(false))
private class ArgFalse {
	
	public function new () {}
	
	public function getExplicitIt ():Iterator<Bool> {
		@yield return true;
	}
	
	public function getNoExplicitIt () {
		@yield return true;
	}
}

// Tests with Expens

@:yield(yield.YieldOption.Explicit, Extend)
private class Parent {
	
	public function new () {};
	
	public function getParentIt ():Iterator<Bool> {
		@yield return true;
	}
}

private class Child extends Parent {
	
	public function new () super();
	
	public function getChildIt ():Iterator<Bool> {
		@yield return true;
	}
}

@:yield(yield.YieldOption.Explicit, Extend(false))
private class IgnoredParent {
	
	public function new () {};
	
	public function getParentIt ():Iterator<Bool> {
		@yield return true;
	}
}

@:yield
private class IgnoredChild extends IgnoredParent {
	
	public function new () super();
	
	public function getChildIt () {
		@yield return true;
	}
}