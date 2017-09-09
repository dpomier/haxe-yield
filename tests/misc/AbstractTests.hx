package misc;

import haxe.unit.TestCase;
import pack.pack1.OperatorOverloading2;
import yield.Yield;
import yield.parser.Parser;

class AbstractTests extends TestCase
{

	public function new() 
	{
		super();
	}
	
	#if (!cs && !java)
	function testOperatorOverloading () {
		var a = new OperatorOverloading("foo");
		var it = a * 3;
		
		assertTrue(it.hasNext());
		assertEquals(new OperatorOverloading("foo"), it.next());
		assertEquals(new OperatorOverloading("foofoo"), it.next());
		assertEquals(new OperatorOverloading("foofoofoo"), it.next());
		assertFalse(it.hasNext());
	}
	#end
	
	#if (!cs && !java)
	function testOperatorOverloadingWrapper () {
		var a = new Wrapper(new OperatorOverloading("foo"));
		var it = a.getSource();
		
		assertTrue(it.hasNext());
		for (i in 0...10) assertEquals(new Wrapper(new OperatorOverloading("foo")), it.next());
		assertTrue(it.hasNext());
		
		var duplicator = a * 4;
		assertTrue(duplicator.hasNext());
		for (j in 0...4) assertEquals(new OperatorOverloading("foo"), duplicator.next());
		assertFalse(duplicator.hasNext());
	}
	#end
	
	#if (!cs && !java)
	function testOperatorOverloading2 () {
		var a = new OperatorOverloading2("bar");
		var it = a / 3;
		
		assertTrue(it.hasNext());
		assertEquals(new OperatorOverloading2("b"), it.next());
		assertEquals(new OperatorOverloading2("a"), it.next());
		assertEquals(new OperatorOverloading2("r"), it.next());
		assertFalse(it.hasNext());
	}
	#end
	
	#if (!cs && !java)
	function testSelectiveFunctions () {
		var a = new SelectiveFunctions("foo");
		var b = new SelectiveFunctions(1);
		
		var it = a.getString();
		assertTrue(it.hasNext());
		for (j in 0...10) assertEquals("foo", it.next());
		assertTrue(it.hasNext());
	}
	#end
	
	#if (!cs && !java) 
	// Warning : Type String is being cast to the unrelated type misc.SFWrapper.T
	function testSelectiveFunctionsWrapper () {
		var a = new SFWrapper(new SelectiveFunctions("bar"));
		var b = new SFWrapper(1);
		
		var it = a.getSource();
		assertTrue(it.hasNext());
		assertEquals(new SelectiveFunctions("bar"), it.next());
		assertEquals("bar", it.next().getString().next());
		assertEquals(new SelectiveFunctions("bar"), it.next());
		assertTrue(it.hasNext());
	}
	#end
	
	function testFunctionStaticTypeParams () {
		
		var it = Statics.makeSource("foobar");
		assertTrue(it.hasNext());
		for (j in 0...10) assertEquals("foobar", it.next());
		assertTrue(it.hasNext());
		
		var it = Statics.testConstraints(["3"]);
		//Statics.testConstraints([3]); // Constraint check failure
	}
	
	#if (!cs && !java)
	function testFunctionTypeParams () {
		
		var a = new AbstractWithConstraints(["5"]);
		//new AbstractWithConstraints([5]); // Constraint check failure
		
		assertTrue(true);
	}
	#end	
	
	function testForwardAbstract () {
		var myForward = new MyForward();
		var it = myForward.numbers();
		
		assertTrue(it.hasNext());
		assertEquals(0, it.next());
		assertEquals(1, it.next());
		assertEquals(2, it.next());
		assertFalse(it.hasNext());
		
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