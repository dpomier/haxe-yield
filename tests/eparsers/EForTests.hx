package eparsers;

import utest.Assert;
import eparsers.EForTests.FuuIterable;

@:yield
class EForTests extends utest.Test {
	
	private static var NULL_INT:Int;

	public function new() {
		super();
		var n:Null<Int> = null;
		NULL_INT = n;
	}
	
	function testSimpleFor () {
		var it = simpleFor();
		
		Assert.equals(4, it.next());
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
		
		Assert.equals(0, it.next());
		Assert.equals(1, it.next());
		Assert.equals(2, it.next());
		Assert.equals(3, it.next());
		
		Assert.equals(NULL_INT, it.next());
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
		Assert.isFalse(it.hasNext());
	}
	
	function multipleYieldedFor ():Iterator<Int> {
		
		var b = 0;
		var y = -1;
		for (i in 0...3) {
			if ((y += 1) >= 3) break;
			@yield return y;
			// i += 1; // Should fail, loop variable cannot be modified
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
		
		Assert.equals(6, it.next());
		Assert.equals(5, it.next());
		Assert.equals(3, it.next());
		
		Assert.isFalse(it.hasNext());
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
		
		Assert.equals(0, it.next());
		Assert.equals(1, it.next());
		Assert.equals(2, it.next());
		Assert.equals(3, it.next());
		Assert.equals(4, it.next());
		
		Assert.isFalse(it.hasNext());
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
		
		Assert.equals(250, it.next());
		
		Assert.equals(25, it.next());
		Assert.equals(50, it.next());
		Assert.equals(75, it.next());
		Assert.equals(100, it.next());
		
		Assert.equals(null, it.next());
		Assert.isFalse(it.hasNext());
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
		
		Assert.equals(25, it.next());
		Assert.equals(50, it.next());
		Assert.equals(75, it.next());
		Assert.equals(100, it.next());
		
		Assert.equals(NULL_INT, it.next());
		
		Assert.equals(3, it.next());
		Assert.equals(2, it.next());
		Assert.equals(1, it.next());
		Assert.equals(0, it.next());
		
		Assert.equals(NULL_INT, it.next());
		Assert.isFalse(it.hasNext());
	}
	function iterator () {
		
		var a:Array<String> = ["25", "50", "75", "100"];
		
		for (i in a.iterator()) {
			@yield return Std.parseInt(i);
		}
		
		@yield return NULL_INT;
		
		#if (neko || js || php || python || lua)
		var n = new FuuIterator();
		#else
		var n:Iterator<Int> = new FuuIterator();
		#end
		
		for (i in n) {
			@yield return i;
		}
		
		@yield return NULL_INT;
	}
	
	function testIteratble () {
		var it = iterable();
		
		Assert.equals(4, it.next());
		Assert.equals(8, it.next());
		Assert.equals(16, it.next());
		
		Assert.equals(null, it.next());
		Assert.isFalse(it.hasNext());
	}
	function iterable (): Iterator<Dynamic> {
		
		var a:Dynamic = { iterator:function () return [4, 8, 16].iterator() };
		
		// for (i in (a) { // FIXME: Can't iterate on a Dynamic value
		for (i in (a:Iterable<Int>)) {
			@yield return i;
		}
		
		@yield return null;
	}
	
	#if !cs // https://github.com/HaxeFoundation/haxe/issues/6474
	function testArrayComprehension () {
		var it = arrayComprehension();
		Assert.isTrue(it.hasNext());
		Assert.equals(Std.string([for (i in 0...3) i]), Std.string(it.next()));
		Assert.equals(Std.string([for (i in 0...5) i]), Std.string(it.next()));
		Assert.isFalse(it.hasNext());
	}
	
	function arrayComprehension () {
		var a:Dynamic = [for (i in 0...3) i];
		@yield return a;
		@yield return [for (i in 0...5) i];
	}
	#end
	
	function testArrayComprehensionAsVarAccession () {
		var it = arrayComprehensionAsVarAccession();
		Assert.isTrue(it.hasNext());
		
		var array:Array<Dynamic> = it.next();
		
		var counter:Int = 0;
		for (getIt in array) {
			Assert.isTrue(Reflect.isFunction(getIt));
			var arrIt = getIt();
			Assert.equals(counter, arrIt.next());
			counter += 1;
		}
		
		Assert.isFalse(it.hasNext());
	}
	
	function arrayComprehensionAsVarAccession () {
		@yield return [for (i in 0...3) function () { @yield return i; }];
	}
	
	function testArrayComprehensionAsVarNestedAccession () {
		var it = arrayComprehensionAsVarNestedAccession();
		Assert.isTrue(it.hasNext());
		
		var array:Array<Dynamic> = it.next();
		
		var counter:Int = 0;
		for (getIt in array) {
			Assert.isTrue(Reflect.isFunction(getIt));
			var arrIt = getIt();
			var getSubIt = arrIt.next();
			Assert.isTrue(Reflect.isFunction(getSubIt));
			
			var subIt = getSubIt();
			Assert.equals(counter, subIt.next());
			counter += 1;
		}
		
		Assert.isFalse(it.hasNext());
	}
	
	function arrayComprehensionAsVarNestedAccession () {
		@yield return [for (i in 0...3) function () { 
			
			@yield return function () {
				@yield return i;
			};
			
		}];
	}
	
	function testLoopVariableCompilation () {
		var it = loopVariableCompilation();
		Assert.isTrue(it.hasNext());
	}
	
	function loopVariableCompilation () {
		
		for (i in 0...20) {
			@yield return i;
            if (i < 1) @yield return i;
			if (i <= 1) @yield return i;
			if (i == 1) @yield return i;
			if (i != 1) @yield return i;
			if (i >= 1) @yield return i;
			if (i > 1) @yield return i;
			if (i + 1 == 1) @yield return i;
			if (i - 1 == 1) @yield return i;
			if (i * 1 == 1) @yield return i;
			if (i / 1 == 1) @yield return i;
			if (i % 1 == 1) @yield return i;
			if ((i & 1) == 1) @yield return i;
			if ((i | 1) == 1) @yield return i;
			if ((i ^ 1) == 1) @yield return i;
			if ((i == 1) && true) @yield return i;
			if ((i == 1) || true) @yield return i;
			if ((i << 1) == 1) @yield return i;
			if ((i >> 1) == 1) @yield return i;
			if ((i >>> 1) == 1) @yield return i;
			if ((i...1) != null) @yield return i;
			if ((0...i) != null) @yield return i;
			if ([i => 0] != null) @yield return i;
            if (-i < 1) @yield return i;
            if (~i < 1) @yield return i;
		}
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