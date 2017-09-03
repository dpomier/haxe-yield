package misc;

import haxe.unit.TestCase;
import misc.pack.MiscFunctions;
import misc.pack.MoreMiscFunctions;
import yield.Yield;
import misc.pack.MoreMiscFunctions.a0 as funcA0;
import misc.pack.MoreMiscFunctions.a1;

@:access(misc.pack.MoreMiscFunctions.priv)
class ImportTests extends TestCase implements Yield
{

	public function new() 
	{
		super();
	}
	
	function testSimpleImport () {
		var it = simpleImport("Patrick");
		
		assertTrue(it.hasNext());
		assertEquals("hello!", it.next());
		assertTrue(it.hasNext());
		assertEquals("hello Toto!", it.next());
		assertTrue(it.hasNext());
		assertEquals("hello Patrick!", it.next());
		assertFalse(it.hasNext());
	}
	
	function simpleImport (name:String): Iterator<String> {
		
		#if (neko || js || php || python || lua)
		var msg = MiscFunctions.hello();
		#else
		var msg:String = MiscFunctions.hello();
		#end
		
		@yield return msg;
		@yield return MiscFunctions.sayHello("Toto");
		@yield return MiscFunctions.sayHello(name);
	}
	
	function testImportField () {
		var it = importField();
		
		assertTrue(it.hasNext());
		assertEquals(1, it.next());
		assertFalse(it.hasNext());
	}
	
	function importField (): Iterator<Int> {
		@yield return a1("");
	}
	
	function testAsImport () {
		var it = asImport();
		
		assertTrue(it.hasNext());
		assertEquals(0, it.next());
		assertFalse(it.hasNext());
	}
	
	function asImport (): Iterator<Int> {
		@yield return funcA0("");
	}
	
	function testAccessField () {
		var it = accessField();
		
		assertTrue(it.hasNext());
		assertEquals(100, it.next());
		assertFalse(it.hasNext());
	}
	
	function accessField (): Iterator<Int> {
		@yield return misc.pack.MoreMiscFunctions.priv("");
	}
	
	function testAccessField2 () {
		var it = accessField2();
		
		assertTrue(it.hasNext());
		assertEquals(200, it.next());
		assertFalse(it.hasNext());
	}
	
	@:access(misc.pack.MoreMiscFunctions.priv2)
	function accessField2 (): Iterator<Int> {
		@yield return misc.pack.MoreMiscFunctions.priv2("");
	}
	
	//function testImportAllowedField () {
		//var it = importAllowedField();
		//
		//assertTrue(it.hasNext());
		//assertEquals(9, it.next());
		//assertFalse(it.hasNext());
	//}
	//
	//function importAllowedField (): Iterator<Int> {
		//@yield return misc.pack.MoreMiscFunctions.MoreMiscFunctionsPriv.d0("");
	//}
	
	//function testImportAll () {
		//var it = importAll();
		//
		//assertTrue(it.hasNext());
		//assertEquals(5, it.next());
		//assertEquals(6, it.next());
		//assertEquals(7, it.next());
		//assertEquals(8, it.next());
		//assertFalse(it.hasNext());
	//}
	//
	//function importAll (): Iterator<Int> {
		//@yield return c0("");
		//@yield return c1("");
		//@yield return c2("");
		//@yield return c3("");
	//}
	
}