package eparsers;

import haxe.unit.TestCase;
import yield.Yield;

class EWhileTests extends TestCase implements Yield
{
	private static var NULL_INT:Int;

	public function new() {
		super();
		var n:Null<Int> = null;
		NULL_INT = n;
	}
	
	function testSimpleWhile () {
		var it = simpleWhile();
		
		assertEquals(4, it.next());
	}
	
	function simpleWhile ():Iterator<Int> {
		
		var a = 0;
		
		while (a < 4) {
			a += 1;
		}
		
		@yield return a;
	}
	
	function testYieldedWhile () {
		var it = yieldedWhile();
		
		assertEquals(0, it.next());
		assertEquals(1, it.next());
		assertEquals(2, it.next());
		assertEquals(3, it.next());
		
		assertEquals(NULL_INT, it.next());
	}
	
	function yieldedWhile ():Iterator<Int> {
		
		var a = 0;
		
		while (a < 4) {
			@yield return a;
			a += 1;
		}
		
		var n:Null<Int> = null;
		var lnull:Int   = n;
		@yield return lnull;
	}
	
	function testMultipleYieldedWhile () {
		var it = multipleYieldedWhile();
		
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
	}
	
	function multipleYieldedWhile ():Iterator<Int> {
		
		var a = 0;
		var b = 0;
		
		while (a < 3) {
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
	
	function testNestedWhile () {
		var it = nestedWhile();
		
		assertEquals(6, it.next());
		assertEquals(1, it.next());
		assertEquals(1, it.next());
		
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
	
	function nestedWhile ():Iterator<Int> {
		
		var a = 0;
		var b = 0;
		var c = 0;
		
		while (a < 3) {
			while (a < 5) {
				while (a < 6) {
					a++;
				}
				b++;
			}
			c++;
		}
		
		@yield return a;
		@yield return b;
		@yield return c;
		
		a = 0;
		b = 10;
		c = 20;
		
		while (a < 3) {
			
			@yield return a;
			
			while (b < 12) {
				
				@yield return b;
				
				while (c < 23) {
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
	
	function testBreakAndContinue () {
		var it = breakAndContinue();
		
		assertTrue(it.hasNext());
		
		assertEquals(0, it.next());
		assertEquals(2, it.next());
		assertEquals(3, it.next());
		assertEquals(100, it.next());
		
		assertFalse(it.hasNext());
	}
	
	function breakAndContinue ():Iterator<Int> {
		var counter:Int = 0;
		
		while (true) {
			
			@yield return counter++;
			if (counter == 3) continue;
			counter++;
			if (counter == 5) break;
		}
		@yield return 100;
	}
	
	function testContinueStatements () {
		var it = continueStatement();
		
		assertTrue(it.hasNext());
		
		assertEquals(0, it.next());
		assertEquals(2, it.next());
		assertEquals(3, it.next());
		assertEquals(4, it.next());
		assertEquals(5, it.next());
		assertEquals(6, it.next());
		assertEquals(7, it.next());
		assertEquals(8, it.next());
		
		assertEquals(18, it.next());
		assertEquals(21, it.next());
		assertEquals(24, it.next());
		assertEquals(27, it.next());
		assertEquals(30, it.next());
		assertEquals(33, it.next());
		
		assertEquals(32, it.next());
		for (i in 0...100) {
			assertEquals(32, it.next());
		}
	}
	
	function continueStatement ():Iterator<Int> {
		var counter:Int = 0;
		
		while (true) {
			
			@yield return counter++;
			
			while (counter < 16) {
				if (++counter > 8) continue;
				@yield return counter;
			}
			
			if (counter > 32) {
				counter = 32;
				continue;
			} else {
				counter += 2;
			}
			
		}
	}
	
	function testDoWhile () {
		var it = doWhile();
		
		assertTrue(it.hasNext());
		
		assertEquals(0, it.next());
		assertEquals(1, it.next());
		assertEquals(2, it.next());
		assertEquals(3, it.next());
		
		assertFalse(it.hasNext());
	}
	
	function doWhile ():Iterator<Int> {
		var i = 0;
		do {
			@yield return i;
		} while (++i < 4);
	}
	
	function testLastPart () {
		var it = lastPart();
		
		assertTrue(it.hasNext());
		
		assertEquals(1, it.next());
		assertEquals(2, it.next());
		assertEquals(3, it.next());
		
		assertEquals(3, it.next());
		assertEquals(5, it.next());
		
		assertFalse(it.hasNext());
	}
	
	function lastPart ():Iterator<Int> {
		var i = 0;
		var val = 0;
		var counter = 0;
		while (++i < 4) {
			@yield return i;
			counter += 1;
		}
		val = 5;
		@yield return counter;
		@yield return val;
	}
	
	function testReturnedValue () {
		
		var it = returnedValue(4);
		assertTrue(it.hasNext());
		assertEquals(Std.string([0,1,2,3]), Std.string(it.next()));
		assertEquals(Std.string([5,6,7]), Std.string(it.next()));
		assertFalse(it.hasNext());
		
	}
	
	function returnedValue (len:Int) {
		
		var i:Int = -1;
		
		var a:Array<Int> = [while (++i < len) i];
		
		@yield return a;
		
		@yield return [while (++i < len * 2) i];
	}
	
	function testIteratorReturnedValue () {
		
		var it = iteratorReturnedValue(4);
		assertTrue(it.hasNext());
		
		var array:Array<Dynamic> = it.next();
		
		assertEquals(4, array.length);
		
		for (elem in array) {
			var subIt = elem();
			assertTrue(subIt.hasNext());
			assertEquals(4, subIt.next());
			assertEquals(8, subIt.next());
			assertFalse(subIt.hasNext());
		}
	}
	
	function iteratorReturnedValue (len:Int) {
		var i:Int = -1;
		var a:Array<Void->Iterator<Int>> = [while (++i < len) {
			function () {
				@yield return i;
				@yield return i*2;
			};
		}];
		
		@yield return a;
	}
}