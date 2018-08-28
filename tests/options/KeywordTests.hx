package options;

import utest.Assert;

class KeywordTests {

	public function new () {
		
	}
	
	function testShortOption () {
		
		var it = new Short().getIt();
		Assert.isTrue(it.next());
		Assert.isTrue(new Short().getBool());
		
	}
	
	function testNormalOption () {
		
		var it = new Normal().getIt();
		Assert.isTrue(it.next());
		Assert.isTrue(new Normal().getBool());
		
	}
	
	function testFullOption () {
		
		var it = new Full().getIt();
		Assert.isTrue(it.next());
		Assert.isTrue(new Full().getBool());
		
	}
	
	function testParentOption () {
		
		var it = new Parent().getParentIt();
		Assert.isTrue(it.next());
		Assert.isTrue(new Parent().getParentBool());
		
		var it = new Child().getChildIt();
		Assert.isTrue(it.next());
		Assert.isTrue(new Child().getChildBool());
		
	}
	
	function testIgnoredParentOption () {
		
		var it = new IgnoredParent().getParentIt();
		Assert.isTrue(it.next());
		Assert.isTrue(new IgnoredParent().getParentBool());
		
		var it = new IgnoredChild().getChildIt();
		Assert.isTrue(it.next());
		Assert.isTrue(new IgnoredChild().getChildBool());
		
	}
	
}



@:yield(Keyword("short"))
private class Short {
	
	public function new () {}
	
	public function getIt ():Iterator<Bool> {
		@short return true;
	}
	
	public function getBool ():Bool {
		@yield return true;
	}
}

@:yield(YieldOption.Keyword("normal"))
private class Normal {
	
	public function new () {}
	
	public function getIt ():Iterator<Bool> {
		@normal return true;
	}
	
	public function getBool ():Bool {
		@yield return true;
	}
	
}

@:yield(yield.YieldOption.Keyword("full"))
private class Full {
	
	public function new () {}
	
	public function getIt ():Iterator<Bool> {
		@full return true;
	}
	
	public function getBool ():Bool {
		@yield return true;
	}
	
}

// Tests with Expens

@:yield(yield.YieldOption.Keyword("parent"), Extend)
private class Parent {
	
	public function new () {};
	
	public function getParentIt ():Iterator<Bool> {
		@parent return true;
	}
	
	public function getParentBool ():Bool {
		@yield return true;
	}
}

private class Child extends Parent {
	
	public function new () super();
	
	public function getChildIt ():Iterator<Bool> {
		@parent return true;
	}
	
	public function getChildBool ():Bool {
		@yield return true;
	}
}

@:yield(yield.YieldOption.Keyword("parent"), Extend(false))
private class IgnoredParent {
	
	public function new () {};
	
	public function getParentIt ():Iterator<Bool> {
		@parent return true;
	}
	
	public function getParentBool ():Bool {
		@yield return true;
	}
}

@:yield
private class IgnoredChild extends IgnoredParent {
	
	public function new () super();
	
	public function getChildIt ():Iterator<Bool> {
		@yield return true;
	}
	
	public function getChildBool ():Bool {
		@parent return true;
	}
}
