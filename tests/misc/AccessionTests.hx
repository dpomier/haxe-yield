package misc;

import haxe.unit.TestCase;
import yield.Yield;

class AccessionTests extends TestCase implements Yield
{

	public function new() 
	{
		super();
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
		var it = this.property();
		assertTrue(it.hasNext());
		assertEquals(0, it.next());
		assertEquals(1, it.next());
		assertEquals(2, it.next());
		assertFalse(it.hasNext());
	}
	
	var property(default, null) = function () {
		
		for (i in 0...3) {
			@yield return i;
		}
	};
}