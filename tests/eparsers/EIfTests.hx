package eparsers;

import utest.Assert;

@:yield
class EIfTests extends utest.Test {
	
	function testSimpleIf () {
		var it = simpleIf();
		
		Assert.equals(1, it.next());
	}
	
	function simpleIf ():Iterator<Dynamic> {
		
		var a = 0;
		var condition = true;
		
		if (condition) {
			a = 1;
		} else {
			a = 2;
		}
		
		@yield return a;
	}
	
	function testYieldIf () {
		var it = yieldIf();
		
		Assert.equals(1, it.next());
		Assert.isTrue(it.hasNext());
		Assert.equals(2, it.next());
		Assert.isFalse(it.hasNext());
	}
	
	function yieldIf ():Iterator<Dynamic> {
		
		var a = 0;
		var condition = true;
		
		if (condition) {
			a = 1;
			@yield return a;
			a = 2;
		} else {
			
		}
		
		@yield return a;
	}
	
	function testYieldIf2 () {
		var it = yieldIf2();
		
		Assert.equals(1, it.next());
		Assert.isTrue(it.hasNext());
		Assert.equals(2, it.next());
		Assert.isFalse(it.hasNext());
	}
	
	function yieldIf2 ():Iterator<Dynamic> {
		
		var a = 0;
		var condition = true;
		
		if (condition) {
			a = 1;
			@yield return a;
			a = 2;
		} else {
			
		}
		
		@yield return a;
	}
	
	function testYieldIfElseTrue () {
		var it = yieldIfElseTrue();
		
		Assert.equals(1, it.next());
		Assert.isTrue(it.hasNext());
		Assert.equals(2, it.next());
		Assert.isFalse(it.hasNext());
		
		// Part 2
		it = yieldIfElseFalse();
		
		Assert.equals(3, it.next());
		Assert.isTrue(it.hasNext());
		Assert.equals(4, it.next());
		Assert.isTrue(it.hasNext());
		Assert.equals(5, it.next());
		Assert.isFalse(it.hasNext());
	}
	
	function yieldIfElseTrue ():Iterator<Dynamic> {
		
		var a = 0;
		var condition = true;
		
		if (condition) {
			a = 1;
			@yield return a;
			a = 2;
		} else {
			
			@yield return 3;
			@yield return 4;
		}
		
		@yield return a;
	}
	
	function yieldIfElseFalse ():Iterator<Dynamic> {
		
		var a = 0;
		var condition = false;
		
		if (condition) {
			a = 1;
			@yield return a;
			a = 2;
		} else {
			
			@yield return 3;
			@yield return 4;
			a = 5;
		}
		
		@yield return a;
	}
	
	function testYieldElse () {
		var it = yieldElse();
		
		Assert.equals(4, it.next());
		Assert.isTrue(it.hasNext());
		Assert.equals(3, it.next());
		Assert.isFalse(it.hasNext());
	}
	
	function yieldElse ():Iterator<Dynamic> {
		
		var a = 0;
		var condition = true;
		
		if (!condition) {
			
		} else {
			@yield return 4;
			a = 3;
		}
		
		@yield return a;
	}
	
	function testYieldElse2 () {
		var it = yieldElse2();
		
		Assert.equals(0, it.next());
		Assert.isFalse(it.hasNext());
	}
	
	function yieldElse2 ():Iterator<Dynamic> {
		
		var a = 0;
		var condition = true;
		
		if (!condition) {
			@yield return 20;
		} else {
			
		}
		
		@yield return a;
	}
	
	function testReturnedValue () {
		
		var it = returnedValue(true);
		Assert.isTrue(it.hasNext());
		Assert.equals(1, it.next());
		Assert.equals(3, it.next());
		Assert.isFalse(it.hasNext());
		
		var it = returnedValue(false);
		Assert.isTrue(it.hasNext());
		Assert.equals(2, it.next());
		Assert.equals(4, it.next());
		Assert.isFalse(it.hasNext());
	}
	
	function returnedValue (condition:Bool) {
		
		var a:Int = if (condition) 1 else 2;
		@yield return a;
		@yield return if (condition) 3 else 4;
	}
	
	function testIteratorReturnedValue () {
		
		var it = iteratorReturnedValue(true);
		Assert.isTrue(it.hasNext());
		
		var it1 = it.next()();
		Assert.equals(1, it1.next());
		Assert.equals(3, it1.next());
		
		var it2 = it.next()();
		Assert.equals(6, it2.next());
		Assert.equals(12, it2.next());
		Assert.isFalse(it.hasNext());
		
		
		
		var it = iteratorReturnedValue(false);
		Assert.isTrue(it.hasNext());
		
		var it1 = it.next()();
		Assert.equals(2, it1.next());
		Assert.equals(4, it1.next());
		
		var it2 = it.next()();
		Assert.equals(8, it2.next());
		Assert.equals(16, it2.next());
		Assert.isFalse(it.hasNext());
	}
	
	function iteratorReturnedValue (condition:Bool) {
		
		var a:Void->Iterator<Int> = if (condition) {
			function () {
				@yield return 1;
				@yield return 3;
			};
		} else {
			function () {
				@yield return 2;
				@yield return 4;
			};
		};
		
		@yield return a;
		
		@yield return if (condition) {
			function () {
				@yield return 6;
				@yield return 12;
			};
		} else {
			function () {
				@yield return 8;
				@yield return 16;
			};
		};
	}
	
	function testInitialization () {
		var it = initialization(2);
		Assert.isTrue(it.hasNext());
		Assert.equals(2, it.next());
		Assert.isFalse(it.hasNext());
	}
	
	function initialization (a:Int) {
		
		var v:Int;
		
		if (a == 0) {
			v = 0;
		} else if (a == 1) {
			throw null;
		} else if (a == 2) {
			v = 2;
		} else {
			v = 3;
		}
		
		@yield return v;
	}
	
}