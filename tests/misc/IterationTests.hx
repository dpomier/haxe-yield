package misc;

import utest.Assert;

@:yield
class IterationTests extends utest.Test {
	
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
			Assert.isTrue(false);
		}
		
		Assert.isTrue(true);
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
		
		Assert.equals(1, it.next());
		Assert.equals(2, it.next());
		Assert.equals(3, it.next());
		Assert.equals(4, it.next());
		Assert.equals(5, it.next());
		Assert.isFalse(it.hasNext());
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
		
		Assert.isTrue(structure.getIterator().hasNext());
		
		#if (neko || js || php || python || lua)
		var it = structure.getIterator();
		#else
		var it:Iterator<Int> = structure.getIterator();
		#end
		
		var expected:Int = 2;
		for (i in structure.getIterator()) {
			Assert.equals(expected, i);
			expected *= 2;
		}
	}
	
}