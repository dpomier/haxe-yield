package options;

import haxe.unit.TestCase;

class ExtendTests extends TestCase {
	
	function testShort () {
		assertTrue(new ChildShort().getIt().next());
		assertTrue(new ChildShort().getChildIt().next());
	}
	
	function testNormal () {
		assertTrue(new ChildNormal().getIt().next());
		assertTrue(new ChildNormal().getChildIt().next());
	}
	
	function testFull () {
		assertTrue(new ChildFull().getIt().next());
		assertTrue(new ChildFull().getChildIt().next());
	}
	
}

@:yield(Extend)
private class Short {
	
	public function new () {}
	
	public function getIt ():Iterator<Bool> {
		@yield return true;
	}
}

private class ChildShort extends Short {
	
	public function new () super();
	
	public function getChildIt ():Iterator<Bool> {
		@yield return true;
	}
	
}

@:yield(YieldOption.Extend)
private class Normal {
	
	public function new () {}
	
	public function getIt ():Iterator<Bool> {
		@yield return true;
	}
	
}

private class ChildNormal extends Normal {
	
	public function new () super();
	
	public function getChildIt ():Iterator<Bool> {
		@yield return true;
	}
	
}

@:yield(yield.YieldOption.Extend)
private class Full {
	
	public function new () {}
	
	public function getIt ():Iterator<Bool> {
		@yield return true;
	}
	
}

private class ChildFull extends Full {
	
	public function new () super();
	
	public function getChildIt ():Iterator<Bool> {
		@yield return true;
	}
	
}