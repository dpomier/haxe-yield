package misc;

import haxe.unit.TestCase;
import pack.pack1.MiscFunctions;
import pack.pack1.MoreMiscFunctions;
import pack.pack1.MoreMiscFunctions.a0 as funcA0;
import pack.pack1.MoreMiscFunctions.a1;
import pack.pack1.MoreMiscFunctions.MoreMiscFunctions3.*;
import pack.pack3.SomeFunctions.*;
import pack.pack2.*;
import yield.Yield;

@:access(pack.pack1.MoreMiscFunctions.priv)
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
		@yield return pack.pack1.MoreMiscFunctions.priv("");
	}
	
	function testAccessField2 () {
		var it = accessField2();
		
		assertTrue(it.hasNext());
		assertEquals(200, it.next());
		assertFalse(it.hasNext());
	}
	
	@:access(pack.pack1.MoreMiscFunctions.priv2)
	function accessField2 (): Iterator<Int> {
		@yield return pack.pack1.MoreMiscFunctions.priv2("");
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
	
	function testAllField () {
		var it = allField();
		
		assertTrue(it.hasNext());
		assertEquals(5, it.next());
		assertEquals(6, it.next());
		assertEquals(7, it.next());
		assertEquals(8, it.next());
		assertFalse(it.hasNext());
	}
	
	function allField (): Iterator<Int> {
		@yield return c0("");
		@yield return c1("");
		@yield return c2("");
		@yield return c3("");
	}
	
	function testAllField2 () {
		var it = allField2();
		
		assertTrue(it.hasNext());
		assertEquals(1, it.next());
		assertEquals(2, it.next());
		assertFalse(it.hasNext());
	}
	
	function allField2 (): Iterator<Int> {
		@yield return f0("");
		@yield return f1("");
	}
	
	function testAllModule () {
		var it = allModule();
		assertTrue(it.hasNext());
		assertEquals("toto1", it.next());
		assertFalse(it.hasNext());
	}
	
	function allModule () {
		@yield return MiscYielded.inlineMethod2("toto").next();
	}
	
}