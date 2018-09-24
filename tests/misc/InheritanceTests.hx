package misc;

import utest.Assert;
import yield.YieldOption;

@:build(yield.parser.Parser.run())
@:yield(YieldOption.Extend)
class Parent extends utest.Test {
	
	private var parentMemeber:Int;

	public function new() {
		super();
		parentMemeber = 14;
	}
	
}

class InheritanceTests extends Parent {
	
	public function new() 
	{
		super();
	}
	
	function testBasic () {
		var it = basic();
		Assert.isTrue(it.hasNext());
		Assert.equals("foo", it.next());
		Assert.equals("bar", it.next());
		Assert.isFalse(it.hasNext());
	}
	
	function basic ():Iterator<String> {
		@yield return "foo";
		@yield return "bar";
	}
	
	function testAccess () {
		var it = access();
		Assert.isTrue(it.hasNext());
		Assert.equals(14, it.next());
		Assert.isFalse(it.hasNext());
	}
	
	function access ():Iterator<Int> {
		@yield return parentMemeber;
	}
	
}