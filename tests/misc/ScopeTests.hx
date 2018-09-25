package misc;

import utest.Assert;
import yield.Yield;

class ScopeTests extends utest.Test implements Yield {
	
	function testEBlock () {
		var it = eblock();
		
		Assert.equals(1, it.next());
	}
	
	function eblock ():Iterator<Dynamic> {
		
		var a = 0;
		
		{
			a = 1;
			var a = 10;
			a += 3;
		}
		
		@yield return a;
	}
	
	function testEBlockY () {
		var it = eblockY();
		
		Assert.equals(null, it.next());
		Assert.equals(null, it.next());
		Assert.equals(1, it.next());
	}
	
	function eblockY ():Iterator<Dynamic> {
		
		var a = 0;
		
		{
			@yield return null;
			a = 1;
			@yield return null;
			var a = 10;
		}
		
		@yield return a;
	}
	
	function testEBlockNestedY () {
		var it = eblockNestedY();
		
		Assert.equals(null, it.next());
		Assert.equals(null, it.next());
		Assert.equals(null, it.next());
		Assert.equals(11, it.next());
		Assert.isFalse(it.hasNext());
	}
	
	function eblockNestedY ():Iterator<Dynamic> {
		
		var a = 0;
		
		{
			{
				{
					@yield return null;
					a = 2;
					{
						a = 1;
						@yield return null;
						var a = 20;
					}
					@yield return null;
					var a = 30;
				}
				a += 10;
			}
		}
		
		@yield return a;
	}
	
	function testEif () {
		var it = eif();
		
		Assert.equals(1, it.next());
	}
	
	function eif ():Iterator<Dynamic> {
		
		var a = 0;
		var condition = true;
		
		if (condition) {
			a = 1;
			var a = 10;
		}
		
		@yield return a;
	}
	
	function testEifY () {
		var it = eifY();
		
		Assert.equals(null, it.next());
		Assert.equals(null, it.next());
		Assert.equals(1, it.next());
	}
	
	function eifY ():Iterator<Dynamic> {
		
		var a = 0;
		var condition = true;
		
		if (condition) {
			@yield return null;
			a = 1;
			@yield return null;
			var a = 10;
		}
		
		@yield return a;
	}
	
	function testEifNestedY () {
		var it = eifNestedY();
		
		Assert.equals(null, it.next());
		Assert.equals(null, it.next());
		Assert.equals(1, it.next());
	}
	
	function eifNestedY ():Iterator<Dynamic> {
		
		var a = 0;
		var condition = true;
		
		if (condition) {
			{
				a = 2;
				@yield return null;
				var a = 10;
			}
			a = a - 1;
			@yield return null;
			var a = 10;
		}
		
		@yield return a;
	}
	
	function testEelse () {
		var it = eelse();
		
		Assert.equals(1, it.next());
	}
	
	function eelse ():Iterator<Dynamic> {
		
		var a = 0;
		var condition = true;
		
		if (!condition) {
			a = 1;
			var a = 10;
		} else {
			a = 1;
			var a = 20;
		}
		
		@yield return a;
	}
	
	function testEelseY () {
		var it = eelseY();
		
		Assert.equals(null, it.next());
		Assert.equals(null, it.next());
		Assert.equals(1, it.next());
	}
	
	function eelseY ():Iterator<Dynamic> {
		
		var a = 0;
		var condition = true;
		
		if (!condition) {
			a = 2;
			@yield return null;
			var a = 20;
			@yield return null;
		} else {
			a = 1;
			@yield return null;
			var a = 10;
			@yield return null;
		}
		
		@yield return a;
	}
	
	function testEelseNestedY () {
		var it = eelseNestedY();
		
		Assert.equals(null, it.next());
		Assert.equals(null, it.next());
		Assert.equals(null, it.next());
		Assert.equals(1, it.next());
	}
	
	function eelseNestedY ():Iterator<Dynamic> {
		
		var a = 0;
		var condition = true;
		
		if (!condition) {
			a = 2;
			@yield return null;
			var a = 20;
			@yield return null;
		} else {
			a = 2;
			{
				@yield return null;
				a += 1;
				var a = 10;
			}
			a -= 2;
			@yield return null;
			var a = 10;
			@yield return null;
		}
		
		@yield return a;
	}
	
	function testEWhile () {
		var it = ewhile();
		
		Assert.equals(1, it.next());
	}
	
	function ewhile ():Iterator<Dynamic> {
		
		var a = 0;
		var i = 1;
		
		while (--i >= 0) {
			++a;
			var a = 10;
		}
		
		@yield return a;
	}
	
	function testEWhileNestedY () {
		var it = ewhileNestedY();
		
		Assert.equals(null, it.next());
		Assert.equals(null, it.next());
		Assert.equals(1, it.next());
	}
	
	function ewhileNestedY ():Iterator<Dynamic> {
		
		var a = 0;
		var i = 1;
		
		while (--i >= 0) {
			a += 2;
			{
				a+=2;
			}
			@yield return null;
			{
				a -= 2;
				@yield return null;
				var a = 10;
			}
			--a;
			var a = 10;
		}
		
		@yield return a;
	}
	
	function testEFor () {
		var it = efor();
		
		Assert.equals(1, it.next());
	}
	
	function efor ():Iterator<Dynamic> {
		
		var a = 0;
		
		for (i in 0...1) {
			++a;
			var a = 10;
		}
		
		@yield return a;
	}
	
	function testEForNestedY () {
		var it = eforNestedY();
		
		Assert.equals(null, it.next());
		Assert.equals(null, it.next());
		Assert.equals(1, it.next());
	}
	
	function eforNestedY ():Iterator<Dynamic> {
		
		var a = 0;
		
		for (i in 0...1) {
			++a;
			{
				++a;
				var b = 1;
				@yield return null;
				{
					a -= b;
					var a = 0;
					@yield return null;
					a -= b;
				}
			}
			var a = 10;
		}
		
		@yield return a;
	}
	
	function testETry () {
		var it = etry();
		
		Assert.equals(1, it.next());
	}
	
	function etry ():Iterator<Dynamic> {
		
		var a = 0;
		
		try {
			++a;
			var a = 10;
		}
		
		@yield return a;
	}
	
	function testECatch () {
		var it = ecatch();
		
		Assert.equals(1, it.next());
	}
	
	function ecatch ():Iterator<Dynamic> {
		
		var a = 0;
		
		try {
			a = 10;
			var a = 20;
			throw null;
		} catch (e:Dynamic) {
			a = 1;
			var a = 30;
		}
		
		@yield return a;
	}
	
	
	function testEfunction () {
		var it = efunction();
		Assert.isTrue(it.hasNext());
		Assert.equals(0, it.next());
		Assert.isFalse(it.hasNext());
	}
	
	function efunction () {
		
		var v:Int = 0;
		
		function f () v = 3;
		
		@yield return v;
	}
	
	function testSelf () {
		var it = self();
		
		Assert.equals(5, it.next());
		Assert.equals(true, it.next());
		Assert.equals(5, it.next());
		Assert.equals(true, it.next());
		
		Assert.equals(false, it.hasNext());
	}
	
	function self ():Iterator<Dynamic> {
		
		#if (neko || js || php || python || lua)
		var a = self();
		#else
		var a:Iterator<Dynamic> = self();
		#end
		
		@yield return 5;
		
		@yield return a.hasNext();
		
		@yield return a.next();
		
		@yield return a.hasNext();
	}
	
	function testNoFinalReturn ():Void {
		
		var result = "";
		
		// Display powers of 2 up to the exponent of 8:
		for (i in noFinalReturn(2, 8)) {
			result += i + " ";
		}
		
		Assert.equals("2 4 8 16 32 64 128 256 ", result);
	}

	function noFinalReturn (number:Int, exponent:Int):Iterator<Int> {
		var result:Int = 1;
		
		for (i in 0...exponent) {
			result = result * number;
			@yield return result;
		}
	}
}