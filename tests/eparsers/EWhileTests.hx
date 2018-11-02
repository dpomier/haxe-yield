package eparsers;

import utest.Assert;

@:yield
class EWhileTests extends utest.Test {
	
	private static var NULL_INT:Int;

	public function new () {
		super();
		var n:Null<Int> = null;
		NULL_INT = n;
	}
	
	function testSimpleWhile () {
		var it = simpleWhile();
		
		Assert.equals(4, it.next());
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
		
		Assert.equals(0, it.next());
		Assert.equals(1, it.next());
		Assert.equals(2, it.next());
		Assert.equals(3, it.next());
		
		Assert.equals(NULL_INT, it.next());
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
		
		Assert.equals(0, it.next());
		Assert.equals(10, it.next());
		Assert.equals(1, it.next());
		
		Assert.equals(1, it.next());
		Assert.equals(10, it.next());
		Assert.equals(2, it.next());
		
		Assert.equals(2, it.next());
		Assert.equals(10, it.next());
		Assert.equals(3, it.next());
		
		Assert.equals(NULL_INT, it.next());
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
		
		Assert.equals(6, it.next());
		Assert.equals(1, it.next());
		Assert.equals(1, it.next());
		
		Assert.equals(0, it.next());
		Assert.equals(10, it.next());
		Assert.equals(21, it.next());
		Assert.equals(22, it.next());
		Assert.equals(23, it.next());
		Assert.equals(11, it.next());
		Assert.equals(1, it.next());
		Assert.equals(2, it.next());
		
		Assert.equals(NULL_INT, it.next());
		
		
		Assert.isFalse(it.hasNext());
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
		
		Assert.isTrue(it.hasNext());
		
		Assert.equals(0, it.next());
		Assert.equals(2, it.next());
		Assert.equals(3, it.next());
		Assert.equals(100, it.next());
		
		Assert.isFalse(it.hasNext());
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
		
		Assert.isTrue(it.hasNext());
		
		Assert.equals(0, it.next());
		Assert.equals(2, it.next());
		Assert.equals(3, it.next());
		Assert.equals(4, it.next());
		Assert.equals(5, it.next());
		Assert.equals(6, it.next());
		Assert.equals(7, it.next());
		Assert.equals(8, it.next());
		
		Assert.equals(18, it.next());
		Assert.equals(21, it.next());
		Assert.equals(24, it.next());
		Assert.equals(27, it.next());
		Assert.equals(30, it.next());
		Assert.equals(33, it.next());
		
		Assert.equals(32, it.next());
		for (i in 0...100) {
			Assert.equals(32, it.next());
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
		
		Assert.isTrue(it.hasNext());
		
		Assert.equals(0, it.next());
		Assert.equals(1, it.next());
		Assert.equals(2, it.next());
		Assert.equals(3, it.next());
		
		Assert.isFalse(it.hasNext());
	}
	
	function doWhile ():Iterator<Int> {
		var i = 0;
		do {
			@yield return i;
		} while (++i < 4);
	}
	
	function testLastPart () {
		var it = lastPart();
		
		Assert.isTrue(it.hasNext());
		
		Assert.equals(1, it.next());
		Assert.equals(2, it.next());
		Assert.equals(3, it.next());
		
		Assert.equals(3, it.next());
		Assert.equals(5, it.next());
		
		Assert.isFalse(it.hasNext());
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
		Assert.isTrue(it.hasNext());
		Assert.equals(Std.string([0,1,2,3]), Std.string(it.next()));
		Assert.equals(Std.string([5,6,7]), Std.string(it.next()));
		Assert.isFalse(it.hasNext());
		
	}
	
	function returnedValue (len:Int) {
		
		var i:Int = -1;
		
		var a:Array<Int> = [while (++i < len) i];
		
		@yield return a;
		
		@yield return [while (++i < len * 2) i];
	}
	
	function testIteratorReturnedValue () {
		
		var it = iteratorReturnedValue(4);
		Assert.isTrue(it.hasNext());
		
		var array:Array<Dynamic> = it.next();
		
		Assert.equals(4, array.length);
		
		for (elem in array) {
			var subIt = elem();
			Assert.isTrue(subIt.hasNext());
			Assert.equals(4, subIt.next());
			Assert.equals(8, subIt.next());
			Assert.isFalse(subIt.hasNext());
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