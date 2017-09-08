package misc;
import haxe.unit.TestCase;
import yield.Yield;

using pack.pack1.MiscFunctions;

using Lambda;

class UsingTests extends TestCase implements Yield
{

	public function new() 
	{
		super();
	}
	
	function testSimpleUsing () {
		var it = simpleUsing("Patrick");
		
		assertTrue(it.hasNext());
		assertEquals("hello !", it.next());
		assertTrue(it.hasNext());
		assertEquals("hello Toto!", it.next());
		assertTrue(it.hasNext());
		assertEquals("hello Patrick!", it.next());
		assertFalse(it.hasNext());
	}
	
	function simpleUsing (name:String): Iterator<Dynamic> {
		
		#if (neko || js || php || python || lua)
		var msg = "".sayHello();
		#else
		var msg:String = "".sayHello();
		#end
		
		@yield return msg;
		@yield return "Toto".sayHello();
		@yield return name.sayHello();
	}
	
	function testLambda () {
		assertEquals(3, lamba().count());
		assertEquals([0,2,4].toString(), lamba().array().toString());
	}
	
	function lamba (): Iterable<Int> {
		@yield return 0;
		@yield return 2;
		@yield return 4;
	}
	
	function testLambaAnonymous () {
		
		var result:List<String> = lamba().flatMap(function (a:Int) {
			@yield return ""+a;
			@yield return ""+a+1;
			@yield return ""+a+2;
		});
		
		var expected:List<String> = new List();
		for (i in ["0", "01", "02", "2", "21", "22", "4", "41", "42"])
			expected.add(i);
		
		assertEquals(expected.toString(), result.toString());
	}
}

