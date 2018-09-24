package options;

import utest.Assert;

class ExtendTests extends utest.Test {
	
	function testShort () {
		Assert.isTrue(new ChildShort().getIt().next());
		Assert.isTrue(new ChildShort().getChildIt().next());
	}
	
	function testNormal () {
		Assert.isTrue(new ChildNormal().getIt().next());
		Assert.isTrue(new ChildNormal().getChildIt().next());
	}
	
	function testFull () {
		Assert.isTrue(new ChildFull().getIt().next());
		Assert.isTrue(new ChildFull().getChildIt().next());
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