package eparsers;




import eparsers.EForTests.FuuIterable;
import yield.Yield;

class EForTests implements Yield
{
	private static var NULL_INT:Int;

	public function new() {
		super();
		var n:Null<Int> = null;
		NULL_INT = n;
	}
	
	function testSimpleFor () {
		var it = simpleFor();
		
		assertEquals(4, it.next());
	}
	
	function simpleFor ():Iterator<Int> {
		
		var a = 0;
		
		for (i in 0...4) {
			a += 1;
		}
		
		@yield return a;
	}
	
	function testYieldedFor () {
		var it = yieldedFor();
		
		assertEquals(0, it.next());
		assertEquals(1, it.next());
		assertEquals(2, it.next());
		assertEquals(3, it.next());
		
		assertEquals(NULL_INT, it.next());
	}
	
	function yieldedFor ():Iterator<Int> {
		
		var a = 0;
		
		for (i in 0...4) {
			a = i;
			@yield return a;
		}
		
		var n:Null<Int> = null;
		var lnull:Int   = n;
		
		@yield return lnull;
	}
	
	function testMultipleYieldedFor () {
		var it = multipleYieldedFor();
		
		assertEquals(0, it.next());
		assertEquals(10, it.next());
		assertEquals(1, it.next());
		
		assertEquals(1, it.next());
		assertEquals(10, it.next());
		assertEquals(2, it.next());
		
		assertEquals(2, it.next());
		assertEquals(10, it.next());
		assertEquals(3, it.next());
		
		assertEquals(NULL_INT, it.next());
		assertFalse(it.hasNext());
	}
	
	function multipleYieldedFor ():Iterator<Int> {
		
		var b = 0;
		
		for (a in 0...3) {
			@yield return a;
			a += 1;
			@yield return 10;
			b += 1;
			@yield return b;
		}
		
		var n:Null<Int> = null;
		var lnull:Int   = n;
		
		@yield return lnull;
	}
	
	function testNestedFor () {
		var it = nestedFor();
		
		assertEquals(6, it.next());
		assertEquals(5, it.next());
		assertEquals(3, it.next());
		
		assertFalse(it.hasNext());
	}
	
	function nestedFor ():Iterator<Int> {
		
		var a = 0;
		var b = 0;
		var c = 0;
		
		for (i in a...3) {
			for (i in a...5) {
				for (i in a...6) {
					a++;
				}
				b++;
			}
			c++;
		}
		
		@yield return a;
		@yield return b;
		@yield return c;
	}
	
	function testNestedForYield () {
		var it = nestedForYield();
		
		assertEquals(0, it.next());
		assertEquals(10, it.next());
		assertEquals(21, it.next());
		assertEquals(22, it.next());
		assertEquals(23, it.next());
		assertEquals(11, it.next());
		assertEquals(1, it.next());
		assertEquals(2, it.next());
		
		assertEquals(NULL_INT, it.next());
		
		assertFalse(it.hasNext());
	}
	
	function nestedForYield ():Iterator<Int> {
		
		var a = 0;
		var b = 0;
		var c = 0;
		
		a = 0;
		b = 10;
		c = 20;
		
		for (i in a...3) {
			
			@yield return a;
			
			for (i in b...12) {
				
				@yield return b;
				
				for (i in c...23) {
					c++;
					@yield return c;
				}
				b++;
			}
			a++;
		}
		
		var n:Null<Int> = null;
		var lnull:Int   = n;
		@yield return lnull;
	}
	
	function testNestedForNestedYield () {
		var it = nestedForNestedYield();
		
		assertEquals(0, it.next());
		assertEquals(1, it.next());
		assertEquals(2, it.next());
		assertEquals(3, it.next());
		assertEquals(4, it.next());
		
		assertFalse(it.hasNext());
	}
	
	function nestedForNestedYield ():Iterator<Int> {
		
		var a = 0;
		
		for (i in 0...3) {
			
			for (i in 0...23) {
				
				if (a != 4) {
					@yield return a;
					a++;
				}
			}
		}
		
		@yield return a;
	}
	
	function testArray () {
		var it = array();
		
		assertEquals(250, it.next());
		
		assertEquals(25, it.next());
		assertEquals(50, it.next());
		assertEquals(75, it.next());
		assertEquals(100, it.next());
		
		assertEquals(null, it.next());
		assertFalse(it.hasNext());
	}
	
	function array (): Iterator<Dynamic> {
		
		#if (neko || js || php || python || lua)
		var a = [25, 50, 75, 100];
		#else
		var a:Array<Int> = [25, 50, 75, 100];
		#end
		
		
		var r = 0;
		
		for (i in 0...a.length) {
			r += a[i];
		}
		
		@yield return r;
		
		for (i in a) {
			@yield return i;
		}
		
		@yield return null;
	}
	
	function testIterator () {
		var it = iterator();
		
		assertEquals(25, it.next());
		assertEquals(50, it.next());
		assertEquals(75, it.next());
		assertEquals(100, it.next());
		
		assertEquals(NULL_INT, it.next());
		
		assertEquals(3, it.next());
		assertEquals(2, it.next());
		assertEquals(1, it.next());
		assertEquals(0, it.next());
		
		assertEquals(NULL_INT, it.next());
		assertFalse(it.hasNext());
	}
	function iterator () {
		
		var a:Array<Int> = [25, 50, 75, 100];
		
		for (i in a.iterator()) {
			@yield return i;
		}
		
		@yield return null;
		
		#if (neko || js || php || python || lua)
		var n = new FuuIterator();
		#else
		var n:Iterator<Int> = new FuuIterator();
		#end
		
		for (i in n) {
			@yield return i;
		}
		
		@yield return null;
	}
	
	function testIteratble () {
		var it = iterable();
		
		assertEquals(4, it.next());
		assertEquals(8, it.next());
		assertEquals(16, it.next());
		
		assertEquals(null, it.next());
		assertFalse(it.hasNext());
	}
	function iterable (): Iterator<Dynamic> {
		
		var a:Dynamic = { iterator:function () return [4, 8, 16].iterator() };
		
		for (i in a) {
			@yield return i;
		}
		
		@yield return null;
	}
	
	function testArrayComprehension () {
		var it = arrayComprehension();
		assertTrue(it.hasNext());
		assertEquals(Std.string([for (i in 0...3) i]), Std.string(it.next()));
		assertEquals(Std.string([for (i in 0...5) i]), Std.string(it.next()));
		assertFalse(it.hasNext());
	}
	
	function arrayComprehension () {
		var a:Dynamic = [for (i in 0...3) i];
		@yield return a;
		@yield return [for (i in 0...5) i];
	}
	
	function testArrayComprehensionAsVarAccession () {
		var it = arrayComprehensionAsVarAccession();
		assertTrue(it.hasNext());
		
		var array:Array<Dynamic> = it.next();
		
		var counter:Int = 0;
		for (getIt in array) {
			assertTrue(Reflect.isFunction(getIt));
			var arrIt = getIt();
			assertEquals(counter, arrIt.next());
			counter += 1;
		}
		
		assertFalse(it.hasNext());
	}
	
	function arrayComprehensionAsVarAccession () {
		@yield return [for (i in 0...3) function () { @yield return i; }];
	}
	
	function testArrayComprehensionAsVarNestedAccession () {
		var it = arrayComprehensionAsVarNestedAccession();
		assertTrue(it.hasNext());
		
		var array:Array<Dynamic> = it.next();
		
		var counter:Int = 0;
		for (getIt in array) {
			assertTrue(Reflect.isFunction(getIt));
			var arrIt = getIt();
			var getSubIt = arrIt.next();
			assertTrue(Reflect.isFunction(getSubIt));
			
			var subIt = getSubIt();
			assertEquals(counter, subIt.next());
			counter += 1;
		}
		
		assertFalse(it.hasNext());
	}
	
	function arrayComprehensionAsVarNestedAccession () {
		@yield return [for (i in 0...3) function () { 
			
			@yield return function () {
				@yield return i;
			};
			
		}];
	}

}

class FuuIterator {
	var i:Int;
	public function new () { i = 4; }
	public function next() { return --i; }
	public function hasNext() { return i > 0; }
}
class FuuIterable {
	public function new () { }
	public function iterator() { return new FuuIterator(); }
}