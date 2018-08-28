package misc;

import utest.Assert;
import pack.pack1.OperatorOverloading2;
import yield.Yield;
import yield.parser.Parser;

class AbstractTests
{

	public function new() 
	{
		
	}
	
	#if (!cs && !java)
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
	
	#if (!cs && !java)
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
	
	#if (!cs && !java)
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
	
	#if (!cs && !java)
	function testSelectiveFunctions () {
		var a = new SelectiveFunctions("foo");
		var b = new SelectiveFunctions(1);
		
		var it = a.getString();
		Assert.isTrue(it.hasNext());
		for (j in 0...10) Assert.equals("foo", it.next());
		Assert.isTrue(it.hasNext());
	}
	#end
	
	#if (!cs && !java) 
	// Warning : Type String is being cast to the unrelated type misc.SFWrapper.T
	function testSelectiveFunctionsWrapper () {
		var a = new SFWrapper(new SelectiveFunctions("bar"));
		var b = new SFWrapper(1);
		
		var it = a.getSource();
		Assert.isTrue(it.hasNext());
		Assert.equals(new SelectiveFunctions("bar"), it.next());
		Assert.equals("bar", it.next().getString().next());
		Assert.equals(new SelectiveFunctions("bar"), it.next());
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
	
	#if (!cs && !java)
	function testFunctionTypeParams () {
		
		var a = new AbstractWithConstraints(["5"]);
		//new AbstractWithConstraints([5]); // Constraint check failure
		
		Assert.isTrue(true);
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

#if (!cs && !java) // error CS1004 repeated modifier
@:build(yield.parser.Parser.run())
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

#if (!cs && !java) // error CS1004 repeated modifier
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

#if (!cs && !java) // error CS1004 repeated modifier
@:build(yield.parser.Parser.run())
abstract SelectiveFunctions<T>(T) from T {
	public function new(t:T) this = t;

	function get() return this;

	@:impl
	static public function getString(v:SelectiveFunctions<String>):Iterator<String> {
		while (true) {
			@yield return v.get();
		}
	}
}
#end

#if (!cs && !java) // build failed
@:build(yield.parser.Parser.run())
abstract SFWrapper<T>(T) from T {
	public function new(t:T) this = t;

	function get() return this;

	@:impl
	static public function getSource(v:SFWrapper<T>):Iterator<T> {
		while (true) {
			@yield return v.get();
		}
	}
}
#end

@:yield
class Statics {
	public static function makeSource<T>(i:T):Iterator<T> {
		while (true) @yield return i;
	}
	
	public static function testConstraints<T:(Iterable<String>, Measurable)>(a:T) {
		if (a.length == 0) @yield break;
		@yield return a.iterator();
	}
}

typedef Measurable = {
  public var length(default, null):Int;
}

#if (!cs && !java) // build failed
@:build(yield.parser.Parser.run())
abstract AbstractWithConstraints<T:(Iterable<String>, Measurable)>(T) from T {
	public function new(t:T) this = t;

	function get() return this;
	

	@:impl
	static public function getSource(v:AbstractWithConstraints<T>):Iterator<T> {
		while (true) {
			@yield return v.get();
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

class MyForwardedClass implements Yield {
	
	public function new () { }
	
	public function numbers () {
		for (i in 0...3) @yield return i;
	}
	
	public function strNumbers () {
		for (i in 0...3) @yield return Std.string(i);
	}
}