package misc;


import yield.YieldOption;

@:build(yield.parser.Parser.run())
@:yield(YieldOption.Extend)
class Parent
{
	private var parentMemeber:Int;

	public function new() 
	{
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
		assertTrue(it.hasNext());
		assertEquals("foo", it.next());
		assertEquals("bar", it.next());
		assertFalse(it.hasNext());
	}
	
	function basic ():Iterator<String> {
		@yield return "foo";
		@yield return "bar";
	}
	
	function testAccess () {
		var it = access();
		assertTrue(it.hasNext());
		assertEquals(14, it.next());
		assertFalse(it.hasNext());
	}
	
	function access ():Iterator<Int> {
		@yield return parentMemeber;
	}
	
}