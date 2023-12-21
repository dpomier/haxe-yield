package misc;

import utest.Assert;
import yield.parser.Parser;

class GenericTests extends utest.Test {
	
	#if (haxe_ver >= 4.000)
	function testSelectiveFunctions () {
		var a = new SelectiveFunctions("foo");
		var it = a.getString();
		Assert.isTrue(it.hasNext());
		for (j in 0...10) Assert.equals("foo", it.next());
		Assert.isTrue(it.hasNext());
		
		var b = new SelectiveFunctions(13);
		var it = b.getAny();
		Assert.isTrue(it.hasNext());
		for (j in 0...10) Assert.equals(13, it.next());
		Assert.isTrue(it.hasNext());
	}
	#end
	
	#if (haxe_ver >= 4.200)
	function testSelectiveFunctionsWrapper () {
		var a = new SFWrapper(new SelectiveFunctions("bar"));
		
		var it = a.getSource();
		Assert.isTrue(it.hasNext());
		Assert.equals(new SelectiveFunctions("bar"), it.next());
		Assert.equals("bar", it.next().getString().next());
		Assert.equals(new SelectiveFunctions("bar"), it.next());
		Assert.isTrue(it.hasNext());
		
		var b = new SFWrapper(8);
		var it = b.getSource();
		Assert.isTrue(it.hasNext());
		for (j in 0...10) Assert.equals(8, it.next());
		Assert.isTrue(it.hasNext());
	}
	#end
	
	function testFunctionStaticTypeParams () {
		
		var it = Statics.makeSource("foobar");
		Assert.isTrue(it.hasNext());
		for (j in 0...10) Assert.equals("foobar", it.next());
		Assert.isTrue(it.hasNext());
		
		var it = Statics.testConstraints(["3"]);
		//Statics.testConstraints([3]); // Constraint check failure
	}
	
	#if (haxe_ver >= 4.200)
	function testFunctionTypeParams () {
		
		var a = new AbstractWithConstraints(["5"]);
		//new AbstractWithConstraints([5]); // Constraint check failure
		
		Assert.isTrue(true);
	}
	#end

	function testGenericType () {
		var g = new GenericTest<Int>(4);
		var it = g.getMore();
		Assert.equals("4", it.next());
		Assert.equals("44", it.next());
		Assert.equals("444", it.next());
	}

	function testAbstractGenericType () {
		var g = new AbstractGenericTest<Int>(8);
		var it = g.getMore();
		Assert.equals("88", it.next());
		Assert.equals("8888", it.next());
	}

	function testGenericFunction () {
		var it = GenericFunctions.getIt(4);
		for (_ in 0...3) Assert.equals(4, it.next());
	}

	function testImplicitGenericFunction () {
		var it = GenericFunctions.getImplicitIt(4);
		for (_ in 0...3) Assert.equals(4, it.next());
	}

	function testGenericFunctionAndType () {
	
		var it = new GenericFunctions().getItCumulatedWithType("foo", 4);
		for (_ in 0...3) Assert.equals(null, it.next());
		var it = new GenericFunctions().getItCumulatedWithType("4", 4);
		for (_ in 0...3) Assert.equals("4", it.next());
	}

	function testImplicitParamConstraint () {
	
		var it = GenericFunctions.getImplicitConstraitIt(4);
		Assert.equals(4, it.next());
		Assert.equals(5, it.next());

		// GenericFunctions.getImplicitConstraitIt("str"); // Should fail with Constraint check failure: String should be Float
	}

	function testNestedGenericFunction () {

		var it1 = new NestedGenericTest(4).getIt();
		var it2 = new NestedGenericTest(12).getIt();
		Assert.equals("foo", it1.next());
		Assert.equals(16, it2.next());
	}

	// function testNestedGenericInGenericFunction () {

	// 	var it1 = new NestedGenericTest(4).getCumulatedIt("foo");
	// 	var it3 = new NestedGenericTest(12).getCumulatedIt("12");
	// 	Assert.equals(null, it1.next());
	// 	Assert.equals(16, it3.next());
	// }
}

#if (haxe_ver >= 4.000)
@:yield
@:using(misc.GenericTests.SelectiveFunctions)
abstract SelectiveFunctions<T>(T) from T {
	public function new(t:T) this = t;

	function get() return this;

	static public function getString(v:SelectiveFunctions<String>):Iterator<String> {
		while (true) {
			@yield return v.get();
		}
	}

	static public function getAny<T>(v:SelectiveFunctions<T>):Iterator<T> {
		while (true) {
			@yield return v.get();
		}
	}
}
#end

#if (haxe_ver >= 4.200)
@:build(yield.parser.Parser.run())
abstract SFWrapper<T>(T) from T {
	public function new(t:T) this = t;

	function get() return this;

	public function getSource():Iterator<T> {
		while (true) {
			@yield return get();
		}
	}
}
#end

@:yield
class Statics {
	public static function makeSource<T>(i:T):Iterator<T> {
		while (true) @yield return i;
	}
	
	#if (haxe_ver < 4.000)
	public static function testConstraints<T:(Iterable<String>, Measurable)>(a:T) {
	#else
	public static function testConstraints<T:Iterable<String> & Measurable>(a:T) {
	#end
		if (a.length == 0) @yield break;
		@yield return a.iterator();
	}
}

typedef Measurable = {
  public var length(default, null):Int;
}

#if (haxe_ver >= 4.200)
@:build(yield.parser.Parser.run())
abstract AbstractWithConstraints<T:Iterable<String> & Measurable>(T) from T {
	public function new(t:T) this = t;

	function get() return this;
	
	public function getSource():Iterator<T> {
		while (true) {
			@yield return get();
		}
	}
}
#end

@:yield
@:generic
class GenericTest <T> {

	var value:T;

	public function new (v:T) {
		value = v;
	}
	
	public function getMore () {
		var s = "";
		while (true) {
			s += value;
			@yield return s;
		}
	}

}

@:yield
@:generic
abstract AbstractGenericTest <T> (String) {

	public function new (v:T) {
		this = Std.string(v);
	}
	
	public function getMore () {
		while (true) {
			this += this;
			@yield return this;
		}
	}

}

@:yield
class GenericFunctions <A> {
	
	public function new () {}

	public static function getIt <T> (v:T):Iterator<T> {

		while (true)
			@yield return v;

	}

	public static function getImplicitIt <T> (v:T) {

		while (true)
			@yield return v;

	}

	public static function getImplicitConstraitIt <T> (v:T) {

		@yield return v;

		@yield return 5.;

	}

	public function getItCumulatedWithType <T> (v:T, a:A) {

		while (true)
			@yield return Std.string(v) == Std.string(a) ? v : null;

	}

}

@:yield
@:generic class NestedGenericTest {

	var v:Int;

	public function new (v:Int) {
		this.v = v;
	}
	
	public function getIt ():Dynamic {

		function it <T> (v:T) {
			@yield return v;
		}
		
		return if (v > 10) {
			it(16);
		} else {
			it("foo");
		}
		

	}
	
	// public function getCumulatedIt <Z> (a:Z):Dynamic {

	// 	function it <Y> (v:Y) {
	// 		@yield return Std.string(v) == Std.string(a) ? v : null;
	// 	}
		
	// 	return if (v > 10) {
	// 		it(16);
	// 	} else {
	// 		it("foo");
	// 	}

	// }

}