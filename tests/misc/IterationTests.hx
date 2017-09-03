package misc;

import haxe.unit.TestCase;
import yield.Yield;

class IterationTests extends TestCase implements Yield
{

	public function new() 
	{
		super();
	}
	
	function testReturnedType () {
		
		try {
			var b = getDynamic();
			b.hasNext();
			b.next();
			b.iterator();
			var c = getIterator();
			c.hasNext();
			c.next();
			var d = getIterable();
			d.iterator();
		} catch (err:Dynamic) {
			assertTrue(false);
		}
		
		assertTrue(true);
	}
	
	function getDynamic ():Dynamic {
		@yield return 5;
	}
	
	function getIterator ():Iterator<Int> {
		@yield return 5;
	}
	
	function getIterable ():Iterable<Int> {
		@yield return 5;
	}
	
	function testIterableAPI () {
		
		var iterable:Iterable<Int> = iterableAPI();
		var it = iterable.iterator();
		
		assertEquals(1, it.next());
		assertEquals(2, it.next());
		assertEquals(3, it.next());
		assertEquals(4, it.next());
		assertEquals(5, it.next());
		assertFalse(it.hasNext());
	}
	
	function iterableAPI (): Iterable<Int> {
		var i = 0;
		while (i++ < 4) {
			@yield return i;
		}
		@yield return 5;
	}
	
	function testStructure () {
		
		var structure = {
			getIterator: function ():Iterator<Int> {
				@yield return 2;
				@yield return 4;
				@yield return 8;
			}
		};
		
		assertTrue(structure.getIterator().hasNext());
		
		#if (neko || js || php || python || lua)
		var it = structure.getIterator();
		#else
		var it:Iterator<Int> = structure.getIterator();
		#end
		
		var expected:Int = 2;
		for (i in structure.getIterator()) {
			assertEquals(expected, i);
			expected *= 2;
		}
	}
	
}