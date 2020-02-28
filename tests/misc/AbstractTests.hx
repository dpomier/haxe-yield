package misc;

import utest.Assert;
import pack.pack1.OperatorOverloading2;
import yield.parser.Parser;

class AbstractTests extends utest.Test {

	function testAbstractReturnType () {
		var it = TestAbstractReturnType.test();
		Assert.equals(3, it.next());
	}
	
	#if (!cs && !java || haxe_ver >= 4.000)
	function testOperatorOverloading () {
		var a = new OperatorOverloading("foo");
		var it = a * 3;
		
		Assert.isTrue(it.hasNext());
		Assert.equals(new OperatorOverloading("foo"), it.next());
		Assert.equals(new OperatorOverloading("foofoo"), it.next());
		Assert.equals(new OperatorOverloading("foofoofoo"), it.next());
		Assert.isFalse(it.hasNext());
	}
	#end
	
	#if (!cs && !java || haxe_ver >= 4.000)
	function testOperatorOverloadingWrapper () {
		var a = new Wrapper(new OperatorOverloading("foo"));
		var it = a.getSource();
		
		Assert.isTrue(it.hasNext());
		for (i in 0...10) Assert.equals(new Wrapper(new OperatorOverloading("foo")), it.next());
		Assert.isTrue(it.hasNext());
		
		var duplicator = a * 4;
		Assert.isTrue(duplicator.hasNext());
		for (j in 0...4) Assert.equals(new OperatorOverloading("foo"), duplicator.next());
		Assert.isFalse(duplicator.hasNext());
	}
	#end
	
	#if (!cs && !java || haxe_ver >= 4.000)
	function testOperatorOverloading2 () {
		var a = new OperatorOverloading2("bar");
		var it = a / 3;
		
		Assert.isTrue(it.hasNext());
		Assert.equals(new OperatorOverloading2("b"), it.next());
		Assert.equals(new OperatorOverloading2("a"), it.next());
		Assert.equals(new OperatorOverloading2("r"), it.next());
		Assert.isFalse(it.hasNext());
	}
	#end
	
	function testForwardAbstract () {
		var myForward = new MyForward();
		var it = myForward.numbers();
		
		Assert.isTrue(it.hasNext());
		Assert.equals(0, it.next());
		Assert.equals(1, it.next());
		Assert.equals(2, it.next());
		Assert.isFalse(it.hasNext());
		
		// MyForward has no field strNumbers
		//myForward.strNumbers();
	}
}

@:yield
class TestAbstractReturnType {
	public static function test ():AbstractIntIterator {
		@yield return 3;
	}
}
@:forward
abstract AbstractIntIterator (Iterator<Int>) { }

#if (!cs && !java || haxe_ver >= 4.000) // error CS1004 repeated modifier
@:yield
abstract OperatorOverloading(String) {
	public inline function new(s:String) {
		this = s;
	}

	@:op(A * B)
	public function repeat(rhs:Int):Iterator<OperatorOverloading> {
		var s:StringBuf = new StringBuf();
		for (i in 0...rhs) {
			s.add(this);
			@yield return new OperatorOverloading(s.toString());
		}
	}
}
#end

#if (!cs && !java || haxe_ver >= 4.000) // error CS1004 repeated modifier
@:build(yield.parser.Parser.run())
abstract Wrapper(OperatorOverloading) {
	public inline function new(s:OperatorOverloading) {
		this = s;
	}

	public function get(rhs:Int):Wrapper {
		return new Wrapper(this);
	}
	
	public function getSource():Iterator<Wrapper> {
		while (true) @yield return new Wrapper(this);
	}
	
	@:op(A * B)
	public function deplicate(rhs:Int):Iterator<OperatorOverloading> {
		for (i in 0...rhs) {
			@yield return this;
		}
	}
}
#end

@:forward(numbers)
abstract MyForward(MyForwardedClass) {
	public inline function new() {
		this = new MyForwardedClass();
	}
}

@:yield
class MyForwardedClass {
	
	public function new () { }
	
	public function numbers () {
		for (i in 0...3) @yield return i;
	}
	
	public function strNumbers () {
		for (i in 0...3) @yield return Std.string(i);
	}
}